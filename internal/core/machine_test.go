package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	coremocks "github.com/hashicorp/vagrant-plugin-sdk/core/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

func TestMachineSetValidId(t *testing.T) {
	tm, _ := TestMinimalMachine(t)

	// Set valid id
	tm.SetID("something")
	newId, err := tm.ID()
	if err != nil {
		t.Errorf("Failed to get id")
	}
	require.Equal(t, newId, "something")

	// Ensure new id is save to db
	dbTarget, err := tm.Client().GetTarget(tm.ctx,
		&vagrant_server.GetTargetRequest{
			Target: tm.Ref().(*vagrant_plugin_sdk.Ref_Target),
		},
	)
	if err != nil {
		t.Errorf("Failed to get target")
	}
	require.Equal(t, dbTarget.Target.Uuid, "something")
}

func TestMachineSetEmptyId(t *testing.T) {
	tm, _ := TestMinimalMachine(t)
	oldId := tm.target.ResourceId

	// Set empty id
	tm.SetID("")
	newId, err := tm.ID()
	if err != nil {
		t.Errorf("Failed to get id")
	}
	require.Equal(t, newId, "")

	// Ensure machine is deleted from the db by checking for the old id
	dbTarget, err := tm.Client().GetTarget(tm.ctx,
		&vagrant_server.GetTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: oldId,
				Project:    tm.target.Project,
				Name:       tm.target.Name,
			},
		},
	)
	require.Nil(t, dbTarget)
	require.Error(t, err)

	// Also check new id
	dbTarget, err = tm.Client().GetTarget(tm.ctx,
		&vagrant_server.GetTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: "",
				Project:    tm.target.Project,
				Name:       tm.target.Name,
			},
		},
	)
	require.Nil(t, dbTarget)
	require.Error(t, err)
}

func TestMachineConfigedGuest(t *testing.T) {
	guestMock := &coremocks.Guest{}
	guestMock.On("Seeds").Return(sdkcore.NewSeeds(), nil)
	guestMock.On("Seed", mock.AnythingOfType("")).Return(nil)

	pluginManager := plugin.TestManager(t,
		plugin.TestPlugin(t,
			plugin.WithPluginName("myguest"),
			plugin.WithPluginComponents(component.GuestType, guestMock)),
	)
	tp := TestProject(t, WithPluginManager(pluginManager))

	tm, _ := TestMachine(t, tp,
		WithTestTargetConfig(&vagrant_plugin_sdk.Vagrantfile_MachineConfig{
			ConfigVm: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{Guest: "myguest"},
		}),
	)
	guest, err := tm.Guest()
	require.NoError(t, err)
	require.NotNil(t, guest)
	require.NotNil(t, tm.guest)
}
