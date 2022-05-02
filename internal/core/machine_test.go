package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
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

func TestMachineGetNonExistentBox(t *testing.T) {
	tp := TestMinimalProject(t)
	tm, _ := TestMachine(t, tp,
		WithTestTargetConfig(&vagrant_plugin_sdk.Vagrantfile_MachineConfig{
			ConfigVm: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{Box: "somebox"},
		}),
	)

	box, err := tm.Box()
	require.NoError(t, err)
	name, err := box.Name()
	require.NoError(t, err)
	require.Equal(t, name, "somebox")
	provider, err := box.Provider()
	require.NoError(t, err)
	require.NotEmpty(t, provider)
	metaurl, err := box.MetadataURL()
	require.NoError(t, err)
	require.Empty(t, metaurl)
}
func TestMachineGetExistentBox(t *testing.T) {
	tp := TestMinimalProject(t)
	tm, _ := TestMachine(t, tp,
		WithTestTargetConfig(&vagrant_plugin_sdk.Vagrantfile_MachineConfig{
			ConfigVm: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{Box: "test/box"},
		}),
	)
	testBox := newFullBox(t, testboxBoxData(), tp.basis)
	testBox.Save()

	box, err := tm.Box()
	require.NoError(t, err)
	name, err := box.Name()
	require.NoError(t, err)
	require.Equal(t, name, "test/box")
	provider, err := box.Provider()
	require.NoError(t, err)
	require.NotEmpty(t, provider)
	metaurl, err := box.MetadataURL()
	require.NoError(t, err)
	require.NotEmpty(t, metaurl)
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

	pluginManager := plugin.TestManager(t,
		plugin.TestPlugin(t,
			BuildTestGuestPlugin("myguest"),
			plugin.WithPluginName("myguest"),
			plugin.WithPluginTypes(component.GuestType),
		),
	)

	for _, tc := range tests {
		tp := TestProject(t, WithPluginManager(pluginManager))
		tm, _ := TestMachine(t, tp,
			WithTestTargetConfig(&vagrant_plugin_sdk.Vagrantfile_MachineConfig{
				ConfigVm: tc.config,
			}),
		)
		guest, err := tm.Guest()
		if tc.errors {
			require.Error(t, err)
			require.Nil(t, guest)
			require.Nil(t, tm.cache.Get("guest"))
		} else {
			require.NoError(t, err)
			require.NotNil(t, guest)
			require.NotNil(t, tm.cache.Get("guest"))
		}
	}
}

func TestMachineNoConfigGuest(t *testing.T) {
	guestMock := BuildTestGuestPlugin("myguest")
	guestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	detectingPlugin := plugin.TestPlugin(t,
		guestMock,
		plugin.WithPluginName("myguest"),
		plugin.WithPluginTypes(component.GuestType),
	)

	notGuestMock := BuildTestGuestPlugin("mynondetectingguest")
	notGuestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(false, nil)
	nonDetectingPlugin := plugin.TestPlugin(t,
		notGuestMock,
		plugin.WithPluginName("mynondetectingguest"),
		plugin.WithPluginTypes(component.GuestType),
	)

	guestChildMock := BuildTestGuestPlugin("myguest-child")
	guestChildMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	guestChildMock.On("Parent").Return("myguest", nil)
	detectingChildPlugin := plugin.TestPlugin(t,
		guestChildMock,
		plugin.WithPluginName("myguest-child"),
		plugin.WithPluginTypes(component.GuestType),
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
			require.Nil(t, tm.cache.Get("guest"))
		} else {
			n, _ := guest.PluginName()
			if n != tc.expectedPluginName {
				t.Error("Found unexpected plugin, ", n)
			}
			require.NoError(t, err)
			require.NotNil(t, guest)
			require.NotNil(t, tm.cache.Get("guest"))
		}
	}
}

func TestMachineSetState(t *testing.T) {
	tm, _ := TestMinimalMachine(t)

	type test struct {
		id    string
		state vagrant_server.Operation_PhysicalState
	}

	tests := []test{
		{id: "running", state: vagrant_server.Operation_CREATED},
		{id: "not_created", state: vagrant_server.Operation_UNKNOWN},
		{id: "whakhgldksj", state: vagrant_server.Operation_UNKNOWN},
	}

	for _, tc := range tests {
		// Set MachineState
		desiredState := &core.MachineState{ID: tc.id}
		tm.SetMachineState(desiredState)
		newState, err := tm.MachineState()
		if err != nil {
			t.Errorf("Failed to get id")
		}
		require.Equal(t, newState, desiredState)

		// Ensure new id is save to db
		dbTarget, err := tm.Client().GetTarget(tm.ctx,
			&vagrant_server.GetTargetRequest{
				Target: tm.Ref().(*vagrant_plugin_sdk.Ref_Target),
			},
		)
		if err != nil {
			t.Errorf("Failed to get target")
		}
		require.Equal(t, dbTarget.Target.State, tc.state)
	}
}

func syncedFolderPlugin(t *testing.T, name string) *plugin.Plugin {
	return plugin.TestPlugin(t,
		BuildTestSyncedFolderPlugin(),
		plugin.WithPluginName(name),
		plugin.WithPluginTypes(component.SyncedFolderType),
	)
}
func TestMachineSyncedFolders(t *testing.T) {
	mySyncedFolder := syncedFolderPlugin(t, "mysyncedfolder")
	myOtherSyncedFolder := syncedFolderPlugin(t, "myothersyncedfolder")

	type test struct {
		plugins         []*plugin.Plugin
		config          *vagrant_plugin_sdk.Vagrantfile_ConfigVM
		errors          bool
		expectedFolders int
	}
	tests := []test{
		// One synced folder and plugin available
		{
			plugins: []*plugin.Plugin{mySyncedFolder},
			errors:  false,
			config: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{
				SyncedFolders: []*vagrant_plugin_sdk.Vagrantfile_SyncedFolder{
					{Source: ".", Destination: "/vagrant", Type: stringPtr("mysyncedfolder")},
				},
			},
			expectedFolders: 1,
		},
		// Many synced folders and available plugins
		{
			plugins: []*plugin.Plugin{mySyncedFolder, myOtherSyncedFolder},
			errors:  false,
			config: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{
				SyncedFolders: []*vagrant_plugin_sdk.Vagrantfile_SyncedFolder{
					{Source: ".", Destination: "/vagrant", Type: stringPtr("mysyncedfolder")},
					{Source: "./two", Destination: "/vagrant-two", Type: stringPtr("mysyncedfolder")},
					{Source: "./three", Destination: "/vagrant-three", Type: stringPtr("myothersyncedfolder")},
				},
			},
			expectedFolders: 3,
		},
		// Synced folder with unavailable plugin
		{
			plugins: []*plugin.Plugin{mySyncedFolder, myOtherSyncedFolder},
			errors:  true,
			config: &vagrant_plugin_sdk.Vagrantfile_ConfigVM{
				SyncedFolders: []*vagrant_plugin_sdk.Vagrantfile_SyncedFolder{
					{Source: ".", Destination: "/vagrant", Type: stringPtr("idontexist")},
					{Source: "./two", Destination: "/vagrant-two", Type: stringPtr("mysyncedfolder")},
					{Source: "./three", Destination: "/vagrant-three", Type: stringPtr("myothersyncedfolder")},
				},
			},
		},
	}

	for _, tc := range tests {
		pluginManager := plugin.TestManager(t, tc.plugins...)
		tp := TestProject(t, WithPluginManager(pluginManager))
		tm, _ := TestMachine(t, tp,
			WithTestTargetConfig(&vagrant_plugin_sdk.Vagrantfile_MachineConfig{ConfigVm: tc.config}),
		)
		folders, err := tm.SyncedFolders()
		if tc.errors {
			require.Error(t, err)
		} else {
			require.NoError(t, err)
			require.NotNil(t, folders)
			require.Len(t, folders, tc.expectedFolders)
		}
	}
}

func stringPtr(s string) *string {
	return &s
}
