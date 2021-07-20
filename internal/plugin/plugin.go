package plugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/builtin/myplugin"
	"github.com/hashicorp/vagrant/builtin/otherplugin"
	"github.com/hashicorp/vagrant/internal/factory"
)

// disable in process plugins by default for now
const IN_PROCESS_PLUGINS = false

var (
	// Builtins is the map of all available builtin plugins and their
	// options for launching them.
	Builtins = map[string][]sdk.Option{
		"myplugin":    myplugin.CommandOptions,
		"otherplugin": otherplugin.CommandOptions,
	}

	// Rubies is a map of all available plugins accessible via the
	// Ruby runtime plugin to legacy Vagrant.
	Rubies = map[string][]sdk.Option{}

	// BaseFactories is the set of base plugin factories. This will include any
	// built-in or well-known plugins by default. This should be used as the base
	// for building any set of factories.
	BaseFactories = map[component.Type]*factory.Factory{
		component.MapperType:       mustFactory(factory.New((*interface{})(nil))),
		component.CommandType:      mustFactory(factory.New(component.TypeMap[component.CommandType])),
		component.CommunicatorType: mustFactory(factory.New(component.TypeMap[component.CommunicatorType])),
		component.ConfigType:       mustFactory(factory.New(component.TypeMap[component.ConfigType])),
		component.GuestType:        mustFactory(factory.New(component.TypeMap[component.GuestType])),
		component.HostType:         mustFactory(factory.New(component.TypeMap[component.HostType])),
		component.LogPlatformType:  mustFactory(factory.New(component.TypeMap[component.LogPlatformType])),
		component.LogViewerType:    mustFactory(factory.New(component.TypeMap[component.LogViewerType])),
		component.ProviderType:     mustFactory(factory.New(component.TypeMap[component.ProviderType])),
		component.ProvisionerType:  mustFactory(factory.New(component.TypeMap[component.ProvisionerType])),
		component.SyncedFolderType: mustFactory(factory.New(component.TypeMap[component.SyncedFolderType])),
		component.PluginInfoType:   mustFactory(factory.New(component.TypeMap[component.PluginInfoType])),
	}
)

func must(err error) {
	if err != nil {
		panic(err)
	}
}

func mustFactory(f *factory.Factory, err error) *factory.Factory {
	must(err)
	return f
}
