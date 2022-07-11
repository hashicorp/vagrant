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
	tm := TestMinimalMachine(t)

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
	tm := TestMinimalMachine(t)
	oldId := tm.target.ResourceId

	// Set empty id
	tm.SetID("")
	newId, err := tm.ID()
	if err != nil {
		t.Errorf("Failed to get id")
	}
	require.Equal(t, newId, "")

	// Machine won't be deleted from db until project is closed, so close project first
	err = tm.project.Close()
	require.NoError(t, err)

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

	// Verify the DataDir still exists (see below test for more detail on why)
	dir, err := tm.DataDir()
	require.NoError(t, err)
	require.DirExists(t, dir.DataDir().String())

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

func TestMachineSetIdBlankThenSomethingPreservesDataDir(t *testing.T) {
	tm := TestMinimalMachine(t)

	// Set empty id, followed by a temp id. This is the same thing that happens
	// in the Docker provider's InitState action
	require.NoError(t, tm.SetID(""))
	require.NoError(t, tm.SetID("preparing"))

	// The DataDir should still exist; the Docker provider relies on this
	// behavior in order for its provisioning sentinel file handling to work
	// properly.
	dir, err := tm.DataDir()
	require.NoError(t, err)
	require.DirExists(t, dir.DataDir().String())
}

func TestMachineGetNonExistentBox(t *testing.T) {
	tp := TestMinimalProject(t)
	tm := TestMachine(t, tp,
		WithTestTargetConfig(testBoxConfig("somebox")),
		WithTestTargetProvider("testprovider"),
	)

	box, err := tm.Box()
	require.NoError(t, err)
	name, err := box.Name()
	require.NoError(t, err)
	require.Equal(t, name, "somebox")
	provider, err := box.Provider()
	require.NoError(t, err)
	require.Equal(t, provider, "testprovider")
	metaurl, err := box.MetadataURL()
	require.NoError(t, err)
	require.Empty(t, metaurl)
}

func TestMachineGetExistentBox(t *testing.T) {
	tp := TestMinimalProject(t)
	tm := TestMachine(t, tp,
		WithTestTargetConfig(testBoxConfig("test/box")),
		WithTestTargetProvider("virtualbox"),
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
	commMock := BuildTestCommunicatorPlugin("ssh")
	commMock.On("Ready", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	commPlugin := plugin.TestPlugin(t,
		commMock,
		plugin.WithPluginName("ssh"),
		plugin.WithPluginTypes(component.CommunicatorType),
	)

	type test struct {
		config *component.ConfigData
		errors bool
	}

	tests := []test{
		{config: testGuestConfig("myguest"), errors: false},
		{config: testGuestConfig("idontexist"), errors: true},
	}
	guestMock := BuildTestGuestPlugin("myguest", "")
	guestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	guestMock.On("Parent").Return("", nil)

	pluginManager := plugin.TestManager(t,
		plugin.TestPlugin(t,
			guestMock,
			plugin.WithPluginName("myguest"),
			plugin.WithPluginTypes(component.GuestType),
		),
		commPlugin,
	)

	for _, tc := range tests {
		tp := TestProject(t, WithPluginManager(pluginManager))
		tm := TestMachine(t, tp,
			WithTestTargetConfig(tc.config),
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
	commMock := BuildTestCommunicatorPlugin("ssh")
	commMock.On("Ready", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	commPlugin := plugin.TestPlugin(t,
		commMock,
		plugin.WithPluginName("ssh"),
		plugin.WithPluginTypes(component.CommunicatorType),
	)

	guestMock := BuildTestGuestPlugin("myguest", "")
	guestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	guestMock.On("Parent").Return("", nil)
	detectingPlugin := plugin.TestPlugin(t,
		guestMock,
		plugin.WithPluginName("myguest"),
		plugin.WithPluginTypes(component.GuestType),
	)

	notGuestMock := BuildTestGuestPlugin("mynondetectingguest", "")
	notGuestMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(false, nil)
	nonDetectingPlugin := plugin.TestPlugin(t,
		notGuestMock,
		plugin.WithPluginName("mynondetectingguest"),
		plugin.WithPluginTypes(component.GuestType),
	)

	guestChildMock := BuildTestGuestPlugin("myguest-child", "myguest")
	guestChildMock.On("Detect", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	guestChildMock.SetParentComponent(guestMock)
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
		{plugins: []*plugin.Plugin{commPlugin, detectingPlugin}, errors: false, expectedPluginName: "myguest"},
		{plugins: []*plugin.Plugin{commPlugin, detectingChildPlugin}, errors: true, expectedPluginName: "myguest-child"},
		{plugins: []*plugin.Plugin{commPlugin, detectingChildPlugin, detectingPlugin}, errors: false, expectedPluginName: "myguest-child"},
		{plugins: []*plugin.Plugin{commPlugin, detectingPlugin, nonDetectingPlugin}, errors: false, expectedPluginName: "myguest"},
		{plugins: []*plugin.Plugin{commPlugin, nonDetectingPlugin}, errors: true},
		{plugins: []*plugin.Plugin{commPlugin}, errors: true},
	}

	for _, tc := range tests {
		pluginManager := plugin.TestManager(t, tc.plugins...)
		tp := TestProject(t, WithPluginManager(pluginManager))

		tm := TestMachine(t, tp)
		guest, err := tm.Guest()
		if tc.errors {
			require.Error(t, err)
			require.Nil(t, guest)
			require.Nil(t, tm.cache.Get("guest"))
		} else {
			require.NoError(t, err)
			require.NotNil(t, guest)
			require.NotNil(t, tm.cache.Get("guest"))
			n, _ := guest.PluginName()
			if n != tc.expectedPluginName {
				t.Error("Found unexpected plugin, ", n)
			}
		}
	}
}

func TestMachineSetState(t *testing.T) {
	tm := TestMinimalMachine(t)

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
		require.Equal(t, tm.machine.State.Id, tc.id)
		require.Equal(t, tm.target.State, tc.state)

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

func TestMachineSyncedFolders(t *testing.T) {
	mySyncedFolder := syncedFolderPlugin(t, "mysyncedfolder")
	myOtherSyncedFolder := syncedFolderPlugin(t, "myothersyncedfolder")

	type test struct {
		plugins         []*plugin.Plugin
		config          *component.ConfigData
		errors          bool
		expectedFolders int
	}
	tests := []test{
		// One synced folder and plugin available
		{
			plugins: []*plugin.Plugin{mySyncedFolder},
			errors:  false,
			config: testSyncedFolderConfig(
				[]*testSyncedFolder{
					{
						source:      ".",
						destination: "/vagrant",
						kind:        "mysyncedfolder",
					},
				},
			),
			expectedFolders: 1,
		},
		// Many synced folders and available plugins
		{
			plugins: []*plugin.Plugin{mySyncedFolder, myOtherSyncedFolder},
			errors:  false,
			config: testSyncedFolderConfig(
				[]*testSyncedFolder{
					{
						source:      ".",
						destination: "/vagrant",
						kind:        "mysyncedfolder",
					},
					{
						source:      "./two",
						destination: "/vagrant-two",
						kind:        "mysyncedfolder",
					},
					{
						source:      "./three",
						destination: "/vagrant-three",
						kind:        "myothersyncedfolder",
					},
				},
			),
			expectedFolders: 3,
		},
		// Synced folder with unavailable plugin
		{
			plugins: []*plugin.Plugin{mySyncedFolder, myOtherSyncedFolder},
			errors:  true,
			config: testSyncedFolderConfig(
				[]*testSyncedFolder{
					{
						source:      ".",
						destination: "/vagrant",
						kind:        "idontexist",
					},
					{
						source:      "./two",
						destination: "/vagrant-two",
						kind:        "mysyncedfolder",
					},
					{
						source:      "./three",
						destination: "/vagrant-three",
						kind:        "myothersyncedfolder",
					},
				},
			),
		},
	}

	for _, tc := range tests {
		pluginManager := plugin.TestManager(t, tc.plugins...)
		tp := TestProject(t, WithPluginManager(pluginManager))
		tm := TestMachine(t, tp,
			WithTestTargetConfig(tc.config),
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
