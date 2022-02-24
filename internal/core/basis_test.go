package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	coremocks "github.com/hashicorp/vagrant-plugin-sdk/core/mocks"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

func TestBasisPlugins(t *testing.T) {
	myguest := plugin.TestPlugin(t,
		plugin.WithPluginName("myguest"),
		plugin.WithPluginMinimalComponents(component.GuestType, &coremocks.Guest{}),
	)
	myguesttwo := plugin.TestPlugin(t,
		plugin.WithPluginName("myguesttwo"),
		plugin.WithPluginMinimalComponents(component.GuestType, &coremocks.Guest{}),
	)
	myhost := plugin.TestPlugin(t,
		plugin.WithPluginName("myhost"),
		plugin.WithPluginMinimalComponents(component.HostType, &coremocks.Host{}),
	)
	mysf := plugin.TestPlugin(t,
		plugin.WithPluginName("mysf"),
		plugin.WithPluginMinimalComponents(component.SyncedFolderType, &coremocks.SyncedFolder{}),
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

func TestBasisNoConfigHost(t *testing.T) {
	hostMock := seededHostMock("myhost")
	hostMock.On("Detect", mock.AnythingOfType("*core.StateBag")).Return(true, nil)
	detectPluginInstance := plugin.TestPluginInstance(t,
		plugin.WithPluginInstanceName("myhost"),
		plugin.WithPluginInstanceType(component.HostType),
		plugin.WithPluginInstanceComponent(hostMock))
	detectingPlugin := plugin.TestPlugin(t,
		plugin.WithPluginName("myhost"),
		plugin.WithPluginInstance(detectPluginInstance))

	notHostMock := seededHostMock("mynondetectinghost")
	notHostMock.On("Detect", mock.AnythingOfType("*core.StateBag")).Return(false, nil)
	nonDetectingPlugin := plugin.TestPlugin(t,
		plugin.WithPluginName("mynondetectinghost"),
		plugin.WithPluginMinimalComponents(component.HostType, notHostMock))

	hostChildMock := seededHostMock("myhost-child")
	hostChildMock.On("Detect", mock.AnythingOfType("*core.StateBag")).Return(true, nil)
	detectChildPluginInstance := plugin.TestPluginInstance(t,
		plugin.WithPluginInstanceName("myhost-child"),
		plugin.WithPluginInstanceType(component.HostType),
		plugin.WithPluginInstanceComponent(hostChildMock),
		plugin.WithPluginInstanceParent(detectPluginInstance))
	detectingChildPlugin := plugin.TestPlugin(t,
		plugin.WithPluginName("myhost-child"),
		plugin.WithPluginInstance(detectChildPluginInstance),
	)

	type test struct {
		plugins            []*plugin.Plugin
		errors             bool
		expectedPluginName string
	}

	tests := []test{
		{plugins: []*plugin.Plugin{detectingPlugin}, errors: false, expectedPluginName: "myhost"},
		{plugins: []*plugin.Plugin{detectingChildPlugin}, errors: false, expectedPluginName: "myhost-child"},
		{plugins: []*plugin.Plugin{detectingChildPlugin, detectingPlugin}, errors: false, expectedPluginName: "myhost-child"},
		{plugins: []*plugin.Plugin{detectingPlugin, nonDetectingPlugin}, errors: false, expectedPluginName: "myhost"},
		{plugins: []*plugin.Plugin{nonDetectingPlugin}, errors: true},
		{plugins: []*plugin.Plugin{}, errors: true},
	}

	for _, tc := range tests {
		pluginManager := plugin.TestManager(t, tc.plugins...)
		b := TestBasis(t,
			WithPluginManager(pluginManager),
		)
		host, err := b.Host()
		if tc.errors {
			require.Error(t, err)
			require.Nil(t, host)
		} else {
			n, _ := host.PluginName()
			if n != tc.expectedPluginName {
				t.Error("Found unexpected plugin, ", n)
			}
			require.NoError(t, err)
			require.NotNil(t, host)
		}
	}
}
