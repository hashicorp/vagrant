package plugin

import (
	"fmt"
	"strings"
	"sync"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/go-plugin"

	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
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
		"myplugin":    myplugin.CommandOptions,
		"otherplugin": otherplugin.CommandOptions,
	}
)

type Plugin struct {
	Builtin       bool                  // Flags if this plugin is a builtin plugin
	Client        plugin.ClientProtocol // Client connection to plugin
	Location      string                // Location of the plugin (generally path to binary)
	Name          string                // Name of the plugin
	Types         []component.Type      // Component types supported by this plugin
	Cache         cacher.Cache
	ParentPlugins []*Plugin

	closers    []func() error
	components map[component.Type]*Instance
	logger     hclog.Logger
	m          sync.Mutex
	src        *plugin.Client
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
	p.closers = append(p.closers, c)
}

// Calls all registered close callbacks
func (p *Plugin) Close() (err error) {
	p.m.Lock()
	defer p.m.Unlock()

	for _, c := range p.closers {
		if e := c(); e != nil {
			multierror.Append(err, e)
		}
	}
	return
}

func (p *Plugin) SetParentPlugins(typ component.Type) {
	i := p.components[typ]
	if i == nil {
		return
	}
	pluginWithParent, ok := i.Component.(PluginWithParent)
	if !ok {
		p.logger.Warn("plugin does not support parents",
			"component", typ.String(),
			"name", p.Name)

	} else {
		p.logger.Info("setting plugin parents",
			"component", typ.String(),
			"name", p.Name)

		parentComponents := []interface{}{}
		for _, pp := range p.ParentPlugins {
			parentComponents = append(parentComponents, pp.components[typ].Component)
		}
		// TODO: set parent plugins
		pluginWithParent.SetParentPlugins(parentComponents)
	}
}

// Get specific component type from plugin
func (p *Plugin) InstanceOf(
	c component.Type,
) (i *Instance, err error) {
	p.m.Lock()
	defer p.m.Unlock()

	p.logger.Trace("loading component from plugin",
		"name", p.Name,
		"type", c.String())

	ok := false
	// Validate this plugin supports the requested component
	for _, t := range p.Types {
		if t == c {
			ok = true
		}
	}
	if !ok {
		p.logger.Error("unsupported component type requested",
			"name", p.Name,
			"type", c.String(),
			"valid", p.types())

		return nil, fmt.Errorf("plugin does not support %s component type", c.String())
	}

	// If it's cached, return that
	if i, ok = p.components[c]; ok {
		p.logger.Trace("using cached component",
			"name", p.Name,
			"type", c.String())

		return
	}

	// Build the instance
	raw, err := p.Client.Dispense(strings.ToLower(c.String()))
	if err != nil {
		p.logger.Error("failed to dispense component from plugin",
			"name", p.Name,
			"type", c.String())

		return
	}
	setter, ok := raw.(PluginMetadata)
	if !ok {
		p.logger.Warn("plugin does not support name metadata, skipping",
			"component", c.String(),
			"name", p.Name)

	} else {
		p.logger.Info("setting plugin name metadata",
			"component", c.String(),
			"name", p.Name)

		setter.SetRequestMetadata("plugin_name", p.Name)
	}

	b, ok := raw.(hasGRPCBroker)
	if !ok {
		p.logger.Error("cannot extract grpc broker from plugin client",
			"component", c.String(),
			"name", p.Name)

		return nil, fmt.Errorf("unable to extract broker from plugin client")
	}

	if c, ok := raw.(interface {
		SetCache(cacher.Cache)
	}); ok {
		c.SetCache(p.Cache)
	}

	i = &Instance{
		Component: raw,
		Broker:    b.GRPCBroker(),
		Mappers:   nil,
	}

	// Store the instance for later usage
	p.components[c] = i

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

type PluginWithParent interface {
	SetParentPlugins([]interface{})
}
