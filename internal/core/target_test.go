// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestTargetSpecializeMachine(t *testing.T) {
	tt := TestMinimalTarget(t)
	specialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	if _, ok := specialized.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}

	// Get machine from the cache, should be the same machine
	reSpecialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	require.Equal(t, reSpecialized, specialized)
}

func TestTargetSpecializeMultiMachine(t *testing.T) {
	p := TestMinimalProject(t)
	tt1 := TestTarget(t, p, &vagrant_server.Target{Name: "tt1"})
	tt2 := TestTarget(t, p, &vagrant_server.Target{Name: "tt2"})

	specialized, err := tt1.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	if _, ok := specialized.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}
	specializedName, _ := specialized.(core.Machine).Name()

	specialized2, err := tt2.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	if _, ok := specialized2.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}
	specialized2Name, _ := specialized2.(core.Machine).Name()

	require.NotEqual(t, specializedName, specialized2Name)
}

func TestTargetSpecializeBad(t *testing.T) {
	tt := TestMinimalTarget(t)
	specialized, err := tt.Specialize((*core.Project)(nil))

	if err != nil {
		t.Errorf("Specialize function returned an error")
	}

	if specialized != nil {
		t.Errorf("Should not specialize to an unsupported type")
	}
}

func TestTargetConfigedCommunicator(t *testing.T) {
	type test struct {
		config *component.ConfigData
		errors bool
	}

	tests := []test{
		{config: testCommunicatorConfig("winrm"), errors: false},
		{config: testSyncedFolderConfig([]*testSyncedFolder{}), errors: false},
		{config: testCommunicatorConfig("idontexist"), errors: true},
	}
	communicatorMockSSH := BuildTestCommunicatorPlugin("ssh")
	communicatorMockWinRM := BuildTestCommunicatorPlugin("winrm")

	pluginManager := plugin.TestManager(t,
		plugin.TestPlugin(t,
			communicatorMockSSH,
			plugin.WithPluginName("ssh"),
			plugin.WithPluginTypes(component.CommunicatorType),
		),
		plugin.TestPlugin(t,
			communicatorMockWinRM,
			plugin.WithPluginName("winrm"),
			plugin.WithPluginTypes(component.CommunicatorType),
		),
	)

	for _, tc := range tests {
		tp := TestProject(t, WithPluginManager(pluginManager))
		tm := TestMachine(t, tp,
			WithTestTargetConfig(tc.config),
		)
		comm, err := tm.Communicate()
		if tc.errors {
			require.Error(t, err)
			require.Nil(t, comm)
		} else {
			require.NoError(t, err)
			require.NotNil(t, comm)
		}
	}
}
