package plugin

import (
	"fmt"
	"strings"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/go-plugin"

	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
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
	Builtin  bool                  // Flags if this plugin is a builtin plugin
	Cache    cacher.Cache          // Cache for plugins to utilize in mappers
	Client   plugin.ClientProtocol // Client connection to plugin
	Location string                // Location of the plugin (generally path to binary)
	Mappers  []*argmapper.Func     // Plugin specific mappers
	Name     string                // Name of the plugin
	Types    []component.Type      // Component types supported by this plugin

	closers    []func() error               // Functions to be called when manager is closed
	components map[component.Type]*Instance // Map of created instances
	logger     hclog.Logger
	m          sync.Mutex
	manager    *Manager       // Plugin manager this plugin belongs to
	src        *plugin.Client // Client for the plugin
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

// Get specific component type from plugin
func (p *Plugin) InstanceOf(
	c component.Type,
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

	// If it's cached, return that
	if i, ok := p.components[c]; ok {
		p.logger.Trace("using cached component",
			"name", p.Name,
			"type", c.String())

		return i, nil
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

	if named, ok := raw.(core.Named); ok {
		named.SetPluginName(p.Name)
		if err != nil {
			return nil, err
		}
	}

	// Create our instance
	i = &Instance{
		Component: raw,
		Broker:    b.GRPCBroker(),
		Mappers:   p.Mappers,
		Name:      p.Name,
		Type:      c,
	}

	// Apply configurations if no errors encountered
	for _, fn := range p.manager.Configurators() {
		if err = fn(i, p.logger); err != nil {
			return
		}
	}

	// Load the parent plugin if available
	if err = p.loadParent(i); err != nil {
		return
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

func (p *Plugin) loadParent(i *Instance) error {
	c, ok := i.Component.(HasParent)
	if !ok {
		p.logger.Debug("component component does not support parents",
			"type", i.Type.String(),
			"name", i.Name,
		)

		return nil
	}

	parentName, err := c.Parent()
	if err != nil {
		p.logger.Error("component parent request failed",
			"type", i.Type.String(),
			"name", i.Name,
			"error", err,
		)

		return err
	}

	// If the parent name is empty, there is no parent
	if parentName == "" {
		return nil
	}

	parentPlugin, err := p.manager.Find(parentName, i.Type)
	if err != nil {
		p.logger.Error("failed to find parent component",
			"type", i.Type.String(),
			"name", i.Name,
			"parent_name", parentName,
			"error", err,
		)

		return err
	}

	pi, err := parentPlugin.InstanceOf(i.Type)
	if err != nil {
		p.logger.Error("failed to load parent component",
			"type", i.Type.String(),
			"name", i.Name,
			"parent_name", parentName,
			"error", err,
		)

		return err
	}

	// Set the parent
	i.Parent = pi
	c.SetParentComponent(pi.Component)

	return nil
}
