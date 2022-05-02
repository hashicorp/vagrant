package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	componentmocks "github.com/hashicorp/vagrant-plugin-sdk/component/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	coremocks "github.com/hashicorp/vagrant-plugin-sdk/core/mocks"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

type TestGuestPlugin struct {
	plugin.TestPluginWithFakeBroker
	coremocks.Guest
}

type TestHostPlugin struct {
	plugin.TestPluginWithFakeBroker
	componentmocks.Host
}

type TestSyncedFolderPlugin struct {
	plugin.TestPluginWithFakeBroker
	componentmocks.SyncedFolder
}

func BuildTestGuestPlugin() *TestGuestPlugin {
	p := &TestGuestPlugin{}
	p.On("SetPluginName", mock.AnythingOfType("string")).Return(nil)
	p.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	p.On("Seeds").Return(core.NewSeeds(), nil)

	return p
}

func BuildTestHostPlugin() *TestHostPlugin {
	p := &TestHostPlugin{}
	p.On("SetPluginName", mock.AnythingOfType("string")).Return(nil)
	p.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	p.On("Seeds").Return(core.NewSeeds(), nil)

	return p
}

func BuildTestSyncedFolderPlugin() *TestSyncedFolderPlugin {
	p := &TestSyncedFolderPlugin{}
	p.On("SetPluginName", mock.AnythingOfType("string")).Return(nil)
	p.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	p.On("Seeds").Return(core.NewSeeds(), nil)

	return p
}

func TestBasisPlugins(t *testing.T) {
	myguest := plugin.TestPlugin(t,
		BuildTestGuestPlugin(),
		plugin.WithPluginName("myguest"),
		plugin.WithPluginTypes(component.GuestType),
	)
	myguesttwo := plugin.TestPlugin(t,
		BuildTestGuestPlugin(),
		plugin.WithPluginName("myguesttwo"),
		plugin.WithPluginTypes(component.GuestType),
	)
	myhost := plugin.TestPlugin(t,
		BuildTestHostPlugin(),
		plugin.WithPluginName("myhost"),
		plugin.WithPluginTypes(component.HostType),
	)
	mysf := plugin.TestPlugin(t,
		BuildTestSyncedFolderPlugin(),
		plugin.WithPluginName("mysf"),
		plugin.WithPluginTypes(component.SyncedFolderType),
	)

	type test struct {
		plugins         []*plugin.Plugin
		pluginType      string
		expectedPlugins int
	}

	tests := []test{
		{plugins: []*plugin.Plugin{myguest, myhost, mysf}, pluginType: "guest", expectedPlugins: 1},
		{plugins: []*plugin.Plugin{myguest, myguesttwo, myhost, mysf}, pluginType: "guest", expectedPlugins: 2},
		{plugins: []*plugin.Plugin{myguest, myguesttwo, myhost, mysf}, pluginType: "host", expectedPlugins: 1},
		{plugins: []*plugin.Plugin{}, pluginType: "host"},
	}

	for _, tc := range tests {
		pluginManager := plugin.TestManager(t, tc.plugins...)
		b := TestBasis(t, WithPluginManager(pluginManager))
		plgs, err := b.Plugins(tc.pluginType)
		require.NoError(t, err)
		require.Len(t, plgs, tc.expectedPlugins)
	}
}

// TODO: (sophia) the ConfigVagrant structure should be at a higher level than Machineconfigs
// func TestBasisConfigedHost(t *testing.T) {
// 	type test struct {
// 		config *vagrant_plugin_sdk.Vagrantfile_Vagrantfile
// 		errors bool
// 	}

// 	tests := []test{
// 		{config: &vagrant_plugin_sdk.Vagrantfile_Vagrantfile{}, errors: false},
// 		{config: &vagrant_plugin_sdk.Vagrantfile_Vagrantfile{}, errors: true},
// 	}

// 	hostMock := seededHostMock("myhost")
// 	pluginManager := plugin.TestManager(t,
// 		plugin.TestPlugin(t,
// 			plugin.WithPluginName("myhost"),
// 			plugin.WithPluginMinimalComponents(component.HostType, hostMock)),
// 	)

// 	for _, tc := range tests {
// 		b := TestBasis(t,
// 			WithPluginManager(pluginManager),
// 			WithTestBasisConfig(tc.config),
// 		)
// 		host, err := b.Host()
// 		if tc.errors {
// 			require.Error(t, err)
// 			require.Nil(t, host)
// 		} else {
// 			require.NoError(t, err)
// 			require.NotNil(t, host)
// 		}
// 	}
// }
