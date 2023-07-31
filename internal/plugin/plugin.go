// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package plugin

import (
	"fmt"
	"io"
	"strings"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"

	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant/builtin/configvagrant"
	"github.com/hashicorp/vagrant/builtin/httpdownloader"
	"github.com/hashicorp/vagrant/builtin/myplugin"
	"github.com/hashicorp/vagrant/builtin/otherplugin"
)

// Setting this value to `true` will run builtin plugins
// in the existing process. This mode of plugin execution
// is not a "supported" mode of the go-plugin library and
// currently should only be used during testing in development
// for determining impact of a large number of builtin
// plugins
const IN_PROCESS_PLUGINS = false

var (
	// Builtins is the map of all available builtin plugins and their
	// options for launching them.
	Builtins = map[string][]sdk.Option{
		"configvagrant":  configvagrant.CommandOptions,
		"myplugin":       myplugin.CommandOptions,
		"otherplugin":    otherplugin.CommandOptions,
		"httpdownloader": httpdownloader.PluginOptions,
	}
)

type Plugin struct {
	Builtin  bool                           // Flags if this plugin is a builtin plugin
	Cache    cacher.Cache                   // Cache for plugins to utilize in mappers
	Client   plugin.ClientProtocol          // Client connection to plugin
	Location string                         // Location of the plugin (generally path to binary)
	Mappers  []*argmapper.Func              // Plugin specific mappers
	Name     string                         // Name of the plugin
	Types    []component.Type               // Component types supported by this plugin
	Options  map[component.Type]interface{} // Options for supported components

	cleaner cleanup.Cleanup // Cleanup tasks to perform on closing
	logger  hclog.Logger
	m       sync.Mutex
	manager *Manager       // Plugin manager this plugin belongs to
	src     *plugin.Client // Client for the plugin
}

// Interface for plugins with mapper support
type HasMappers interface {
	AppendMappers(...*argmapper.Func)
}

// Interface for plugins which allow broker access
type HasGRPCBroker interface {
	GRPCBroker() *plugin.GRPCBroker
}

// Interface for plugins that allow setting request metadata
type HasPluginMetadata interface {
	SetRequestMetadata(k, v string)
}

// Interface for plugins that support having a parent
type HasParent interface {
	GetParentComponent() interface{}
	Parent() (string, error)
	SetParentComponent(interface{})
}

// Returns the plugin manager instance this plugin is attached
func (p *Plugin) Manager() *Manager {
	return p.manager
}

// Get a component from the plugin. This will load the component via
// the configured plugin manager so all expected caching and configuration
// will occur.
func (p *Plugin) Component(t component.Type) (interface{}, error) {
	i, err := p.manager.Find(p.Name, t)
	if err != nil {
		return nil, err
	}

	return i.Component, nil
}

// Check if plugin implements specific component type
func (p *Plugin) HasType(
	t component.Type,
) bool {
	for _, pt := range p.Types {
		if pt == t {
			return true
		}
	}
	return false
}

// Add a callback to execute when plugin is closed
func (p *Plugin) Closer(c func() error) {
	p.cleaner.Do(c)
}

// Calls all registered close callbacks
func (p *Plugin) Close() (err error) {
	p.m.Lock()
	defer p.m.Unlock()

	return p.cleaner.Close()
}

// Get specific component type from plugin. This is not exported
// as it should not be called directly. The plugin manager should
// be used for loading component instances so all callbacks are
// applied appropriately and caching will be respected
func (p *Plugin) instanceOf(
	c component.Type,
	cfns []PluginConfigurator,
) (i *Instance, err error) {
	p.m.Lock()
	defer p.m.Unlock()

	p.logger.Trace("loading component from plugin",
		"name", p.Name,
		"type", c.String())

	if !p.HasType(c) {
		p.logger.Error("unsupported component type requested",
			"name", p.Name,
			"type", c.String(),
			"valid", p.types())

		return nil, fmt.Errorf("plugin does not support %s component type", c.String())
	}

	// Build the instance
	raw, err := p.Client.Dispense(strings.ToLower(c.String()))
	if err != nil {
		p.logger.Error("failed to dispense component from plugin",
			"name", p.Name,
			"type", c.String())

		return
	}

	// Extract the GRPC broker if possible
	b, ok := raw.(HasGRPCBroker)
	if !ok {
		p.logger.Error("cannot extract grpc broker from plugin client",
			"component", c.String(),
			"name", p.Name)

		return nil, fmt.Errorf("unable to extract broker from plugin client")
	}

	// Include any mappers provided by the plugin
	if cm, ok := raw.(HasMappers); ok {
		cm.AppendMappers(p.Mappers...)
	}

	// Set the plugin name if possible
	if named, ok := raw.(core.Named); ok {
		named.SetPluginName(p.Name)
		if err != nil {
			return nil, err
		}
	}

	// Create our instance
	i = &Instance{
		Component: raw,
		Close: func() error {
			if cl, ok := raw.(io.Closer); ok {
				return cl.Close()
			}
			return nil
		},
		Broker:  b.GRPCBroker(),
		Mappers: p.Mappers,
		Name:    p.Name,
		Type:    c,
		Options: p.Options[c],
	}

	// Be sure the instance is close when the plugin is closed
	p.Closer(func() error {
		return i.Close()
	})

	// Apply configurators to the instance
	for _, fn := range cfns {
		if err = fn(i, p.logger); err != nil {
			return
		}
	}

	return
}

// Helper that returns supported types as strings
func (p *Plugin) types() []string {
	result := []string{}
	for _, t := range p.Types {
		result = append(result, t.String())
	}
	return result
}
