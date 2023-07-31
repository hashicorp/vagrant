// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/stretchr/testify/require"
)

func TestBasisPlugins(t *testing.T) {
	myguest := plugin.TestPlugin(t,
		BuildTestGuestPlugin("myguest", ""),
		plugin.WithPluginName("myguest"),
		plugin.WithPluginTypes(component.GuestType),
	)
	myguesttwo := plugin.TestPlugin(t,
		BuildTestGuestPlugin("myguesttwo", ""),
		plugin.WithPluginName("myguesttwo"),
		plugin.WithPluginTypes(component.GuestType),
	)
	myhost := plugin.TestPlugin(t,
		BuildTestHostPlugin("myhost", ""),
		plugin.WithPluginName("myhost"),
		plugin.WithPluginTypes(component.HostType),
	)
	mysf := plugin.TestPlugin(t,
		BuildTestSyncedFolderPlugin(""),
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
