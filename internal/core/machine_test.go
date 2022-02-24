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

func seededGuestMock(name string) *coremocks.Guest {
	guestMock := &coremocks.Guest{}
	guestMock.On("Seeds").Return(sdkcore.NewSeeds(), nil)
	guestMock.On("Seed", mock.AnythingOfType("")).Return(nil)
	guestMock.On("PluginName").Return(name, nil)
	return guestMock
}

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
	type test struct {
		config *vagrant_plugin_sdk.Vagrantfile_ConfigVM
		errors bool
	}

	tests := []test{
		{config: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{Guest: "myguest"}, errors: false},
		{config: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{Guest: "idontexist"}, errors: true},
	}

	guestMock := seededGuestMock("myguest")
	pluginManager := plugin.TestManager(t,
		plugin.TestPlugin(t,
			plugin.WithPluginName("myguest"),
			plugin.WithPluginMinimalComponents(component.GuestType, guestMock)),
	)
	tp := TestProject(t, WithPluginManager(pluginManager))

	for _, tc := range tests {
		tm, _ := TestMachine(t, tp,
			WithTestTargetConfig(&vagrant_plugin_sdk.Vagrantfile_MachineConfig{
				ConfigVm: tc.config,
			}),
		)
		guest, err := tm.Guest()
		if tc.errors {
			require.Error(t, err)
			require.Nil(t, guest)
			require.Nil(t, tm.guest)
		} else {
			require.NoError(t, err)
			require.NotNil(t, guest)
			require.NotNil(t, tm.guest)
		}
	}
}

func TestMachineNoConfigGuest(t *testing.T) {
	guestMock := seededGuestMock("myguest")
	guestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	detectPluginInstance := plugin.TestPluginInstance(t,
		plugin.WithPluginInstanceName("myguest"),
		plugin.WithPluginInstanceType(component.GuestType),
		plugin.WithPluginInstanceComponent(guestMock))
	detectingPlugin := plugin.TestPlugin(t,
		plugin.WithPluginName("myguest"),
		plugin.WithPluginInstance(detectPluginInstance))

	notGuestMock := seededGuestMock("mynondetectingguest")
	notGuestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(false, nil)
	nonDetectingPlugin := plugin.TestPlugin(t,
		plugin.WithPluginName("mynondetectingguest"),
		plugin.WithPluginMinimalComponents(component.GuestType, notGuestMock))

	guestChildMock := seededGuestMock("myguest-child")
	guestChildMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	detectChildPluginInstance := plugin.TestPluginInstance(t,
		plugin.WithPluginInstanceName("myguest-child"),
		plugin.WithPluginInstanceType(component.GuestType),
		plugin.WithPluginInstanceComponent(guestChildMock),
		plugin.WithPluginInstanceParent(detectPluginInstance))
	detectingChildPlugin := plugin.TestPlugin(t,
		plugin.WithPluginName("myguest-child"),
		plugin.WithPluginInstance(detectChildPluginInstance),
	)

	type test struct {
		plugins            []*plugin.Plugin
		errors             bool
		expectedPluginName string
	}

	tests := []test{
		{plugins: []*plugin.Plugin{detectingPlugin}, errors: false, expectedPluginName: "myguest"},
		{plugins: []*plugin.Plugin{detectingChildPlugin}, errors: false, expectedPluginName: "myguest-child"},
		{plugins: []*plugin.Plugin{detectingChildPlugin, detectingPlugin}, errors: false, expectedPluginName: "myguest-child"},
		{plugins: []*plugin.Plugin{detectingPlugin, nonDetectingPlugin}, errors: false, expectedPluginName: "myguest"},
		{plugins: []*plugin.Plugin{nonDetectingPlugin}, errors: true},
		{plugins: []*plugin.Plugin{}, errors: true},
	}

	for _, tc := range tests {
		pluginManager := plugin.TestManager(t, tc.plugins...)
		tp := TestProject(t, WithPluginManager(pluginManager))

		tm, _ := TestMachine(t, tp, WithTestTargetMinimalConfig())
		guest, err := tm.Guest()
		if tc.errors {
			require.Error(t, err)
			require.Nil(t, guest)
			require.Nil(t, tm.guest)
		} else {
			n, _ := guest.PluginName()
			if n != tc.expectedPluginName {
				t.Error("Found unexpected plugin, ", n)
			}
			require.NoError(t, err)
			require.NotNil(t, guest)
			require.NotNil(t, tm.guest)
		}
	}
}
