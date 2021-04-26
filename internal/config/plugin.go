package config

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant"
)

type Type uint

const (
	InvalidType Type = iota // Invalid
	RubyType                // Ruby
	BuiltinType             // Builtin
)

// Plugin configures a plugin.
type Plugin struct {
	// Name of the plugin. This is expected to match the plugin binary
	// "vagrant-plugin-<name>" including casing.
	// TODO(spox): I want to remove the link between name and executable
	//             file name. Since we will be loading up all our plugins,
	//             I'd much rather the name to be provided via the component
	//             interface
	Name string

	// Type is the type of plugin this is. This can be multiple.
	Type struct {
		Builtin      bool
		Mapper       bool
		Provider     bool
		Provisioner  bool
		Ruby         bool
		Command      bool
		Communicator bool
		Guest        bool
		Host         bool
		SyncedFolder bool
		Config       bool
		LogViewer    bool
		LogPlatform  bool
	}

	// Checksum is the SHA256 checksum to validate this plugin.
	Checksum string
}

// Plugins returns all the plugins defined by this configuration. This
// will include Ruby plugins
// TODO: (sophia) Revisit this implementation
func (c *Config) Plugins() []*Plugin {
	result := make([]*Plugin, len(c.Plugin))
	copy(result, c.Plugin)
	return result
}

func (c *Config) TrackRubyPlugin(name string, typs []interface{}) {
	t := append(typs, RubyType)
	c.TrackPlugin(name, t)
}

func (c *Config) TrackBuiltinPlugin(name string, typs []interface{}) {
	t := append(typs, BuiltinType)
	c.TrackPlugin(name, t)
}

func (c *Config) TrackPlugin(name string, typs []interface{}) {
	var known *Plugin
	result := make([]*Plugin, len(c.Plugin))
	copy(result, c.Plugin)

	// Check if this plugin name is already registered
	// TODO(spox): we need to change this flow to prevent multiple plugins with same name
	for i := 0; i < len(c.Plugin); i++ {
		if result[i].Name == name {
			known = result[i]
			break
		}
	}

	// If it's not known, make it
	if known == nil {
		known = &Plugin{Name: name}
	}

	// Mark the component types
	for _, typ := range typs {
		known.markType(typ)
	}

	// Add and store the result
	result = append(result, known)
	c.Plugin = result
}

// Types returns the list of types that this plugin implements.
func (p *Plugin) Types() []component.Type {
	var result []component.Type
	for t, b := range p.typeMap() {
		if *b {
			result = append(result, t)
		}
	}

	return result
}

// markType marks that the given component type is supported by this plugin.
// This will panic if an unsupported plugin type is given.
func (p *Plugin) markType(typ interface{}) {
	m := p.pluginMap()
	b, ok := m[typ]
	if !ok {
		panic("unknown type: " + typ.(string))
	}

	*b = true
}

func (p *Plugin) typeMap() map[component.Type]*bool {
	return map[component.Type]*bool{
		component.MapperType:       &p.Type.Mapper,
		component.CommandType:      &p.Type.Command,
		component.CommunicatorType: &p.Type.Communicator,
		component.GuestType:        &p.Type.Guest,
		component.HostType:         &p.Type.Host,
		component.ProviderType:     &p.Type.Provider,
		component.ProvisionerType:  &p.Type.Provisioner,
		component.SyncedFolderType: &p.Type.SyncedFolder,
	}
}

func (p *Plugin) pluginMap() map[interface{}]*bool {
	return map[interface{}]*bool{
		BuiltinType:                       &p.Type.Builtin,
		RubyType:                          &p.Type.Ruby,
		component.MapperType:              &p.Type.Mapper,
		component.CommandType:             &p.Type.Command,
		component.CommunicatorType:        &p.Type.Communicator,
		component.GuestType:               &p.Type.Guest,
		component.HostType:                &p.Type.Host,
		component.ProviderType:            &p.Type.Provider,
		component.ProvisionerType:         &p.Type.Provisioner,
		component.SyncedFolderType:        &p.Type.SyncedFolder,
		component.ConfigType:              &p.Type.Config,
		component.LogPlatformType:         &p.Type.LogPlatform,
		component.LogViewerType:           &p.Type.LogViewer,
		ruby_vagrant.Plugin_COMMAND:       &p.Type.Command,
		ruby_vagrant.Plugin_COMMUNICATOR:  &p.Type.Communicator,
		ruby_vagrant.Plugin_GUEST:         &p.Type.Guest,
		ruby_vagrant.Plugin_HOST:          &p.Type.Host,
		ruby_vagrant.Plugin_PROVIDER:      &p.Type.Provider,
		ruby_vagrant.Plugin_PROVISIONER:   &p.Type.Provisioner,
		ruby_vagrant.Plugin_SYNCED_FOLDER: &p.Type.SyncedFolder,
	}
}
