package plugin

import (
	"fmt"
	"strings"
	"sync"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/go-plugin"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
)

type Manager struct {
	Plugins []*Plugin

	logger hclog.Logger
	m      sync.Mutex
}

// Create a new plugin manager
func NewManager(l hclog.Logger) *Manager {
	return &Manager{
		Plugins: []*Plugin{},
		logger:  l,
	}
}

type Plugin struct {
	Builtin  bool                  // Flags if this plugin is a builtin plugin
	Client   plugin.ClientProtocol // Client connection to plugin
	Location string                // Location of the plugin (generally path to binary)
	Name     string                // Name of the plugin
	Types    []component.Type      // Component types supported by this plugin

	closers    []func() error
	components map[component.Type]*Instance
	logger     hclog.Logger
	m          sync.Mutex
	src        *plugin.Client
}

// Register a new plugin into the manager
func (m *Manager) Register(
	factory func(hclog.Logger) (*Plugin, error), // Function to generate plugin
) (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	plg, err := factory(m.logger)
	if err != nil {
		return
	}

	for _, t := range plg.Types {
		m.logger.Info("registering plugin",
			"type", t.String(),
			"name", plg.Name,
		)
	}

	m.Plugins = append(m.Plugins, plg)
	return
}

// Find a specific plugin by name and component type
func (m *Manager) Find(
	n string, // Name of the plugin
	t component.Type, // component type of plugin
) (p *Plugin, err error) {
	for _, p = range m.Plugins {
		if p.Name == n && p.HasType(t) {
			return
		}
	}
	return nil, fmt.Errorf("failed to locate plugin `%s`", n)
}

// Find all plugins which support a specific component type
func (m *Manager) Typed(
	t component.Type, // Type of plugins
) ([]*Plugin, error) {
	m.logger.Trace("searching for plugins",
		"type", t.String())

	result := []*Plugin{}
	for _, p := range m.Plugins {
		if p.HasType(t) {
			result = append(result, p)
		}
	}

	m.logger.Trace("plugin search complete",
		"type", t.String(),
		"count", len(result))

	return result, nil
}

// Close the manager (and all managed plugins)
func (m *Manager) Close() (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	for _, p := range m.Plugins {
		if e := p.Close(); e != nil {
			err = multierror.Append(err, e)
		}
	}
	return
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
