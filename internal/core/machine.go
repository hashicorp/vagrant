package core

import (
	"fmt"
	"os/user"
	"reflect"
	"sort"

	"github.com/mitchellh/mapstructure"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Machine struct {
	*Target
	box     *Box
	machine *vagrant_server.Target_Machine
	logger  hclog.Logger
	cache   cacher.Cache
}

// Close implements core.Machine
func (m *Machine) Close() (err error) {
	return
}

// ID implements core.Machine
func (m *Machine) ID() (id string, err error) {
	return m.machine.Id, nil
}

// SetID implements core.Machine
func (m *Machine) SetID(value string) (err error) {
	m.machine.Id = value

	// Also set uid
	user, err := user.Current()
	if err != nil {
		return err
	}
	m.machine.Uid = user.Uid

	// Persist changes
	if value == "" {
		m.target.Record = nil
		err = m.Destroy()
	} else {
		err = m.SaveMachine()
	}

	return
}

func (m *Machine) Box() (b core.Box, err error) {
	if m.box == nil {
		boxes, _ := m.project.Boxes()
		boxName := m.Config().ConfigVm.Box
		// Get the first provider available - that's the one that
		// will be used to launch the machine
		provider, err := m.ProviderName()
		if err != nil {
			return nil, err
		}
		b, err := boxes.Find(boxName, "", provider)
		if err != nil {
			return nil, err
		}
		if b == nil {
			return &Box{
				basis: m.project.basis,
				box: &vagrant_server.Box{
					Name:     boxName,
					Provider: provider,
				},
			}, nil
		}
		m.machine.Box = b.(*Box).ToProto()
		m.SaveMachine()
		m.box = b.(*Box)
	}

	return m.box, nil
}

// Guest implements core.Machine
func (m *Machine) Guest() (g core.Guest, err error) {
	defer func() {
		if g != nil {
			err = seedPlugin(g, m)
			if err == nil {
				m.cache.Register("guest", g)
			}
		}
	}()

	i := m.cache.Get("guest")
	if i != nil {
		return i.(core.Guest), nil
	}

	// Check if a guest is provided by the Vagrantfile. If it is, then try
	// to use that guest
	// TODO: This check maybe needs to get reworked when the Vagrantfile bits
	// actually start getting used
	if m.target.Configuration.ConfigVm.Guest != "" {
		// Ignore error about guest not being found - will also try detecting the guest
		guest, cerr := m.project.basis.component(
			m.ctx, component.GuestType, m.target.Configuration.ConfigVm.Guest)
		if cerr != nil {
			return nil, cerr
		}
		if guest != nil {
			g = guest.Value.(core.Guest)
			return
		}
	}

	// Try to detect a guest
	guests, err := m.project.basis.typeComponents(m.ctx, component.GuestType)
	if err != nil {
		return
	}

	names := make([]string, 0, len(guests))
	pcount := map[string]int{}

	for name, g := range guests {
		names = append(names, name)
		pcount[name] = g.plugin.ParentCount()
	}

	sort.Slice(names, func(i, j int) bool {
		in := names[i]
		jn := names[j]
		// TODO check values exist before use
		return pcount[in] > pcount[jn]
	})

	for _, name := range names {
		guest := guests[name].Value.(core.Guest)
		detected, gerr := guest.Detect(m.toTarget())
		if gerr != nil {
			m.logger.Error("guest error on detection check",
				"plugin", name,
				"type", "Guest",
				"error", err)

			continue
		}
		if detected {
			m.logger.Info("guest detection complete",
				"name", name,
			)
			g = guest
			return
		}
	}

	return nil, fmt.Errorf("failed to detect guest plugin for current platform")
}

func (m *Machine) Inspect() (printable string, err error) {
	name, err := m.Name()
	provider, err := m.Provider()
	printable = "#<" + reflect.TypeOf(m).String() + ": " + name + " (" + reflect.TypeOf(provider).String() + ")>"
	return
}

// ConnectionInfo implements core.Machine
func (m *Machine) ConnectionInfo() (info *core.ConnectionInfo, err error) {
	// TODO: need Vagrantfile
	return
}

// MachineState implements core.Machine
func (m *Machine) MachineState() (state *core.MachineState, err error) {
	p, err := m.Provider()
	if err != nil {
		return nil, err
	}
	return p.State()
}

// SetMachineState implements core.Machine
func (m *Machine) SetMachineState(state *core.MachineState) (err error) {
	var st *vagrant_plugin_sdk.Args_Target_Machine_State
	mapstructure.Decode(state, &st)
	m.machine.State = st

	switch st.Id {
	case "not_created":
		m.target.State = vagrant_server.Operation_UNKNOWN
	case "running":
		m.target.State = vagrant_server.Operation_CREATED
	case "poweroff":
		m.target.State = vagrant_server.Operation_DESTROYED
	case "pending":
		m.target.State = vagrant_server.Operation_PENDING
	default:
		m.target.State = vagrant_server.Operation_UNKNOWN
	}

	return m.SaveMachine()
}

func (m *Machine) UID() (userId string, err error) {
	return m.machine.Uid, nil
}

func StringToPathFunc() mapstructure.DecodeHookFunc {
	return func(
		f reflect.Type,
		t reflect.Type,
		data interface{}) (interface{}, error) {
		if f.Kind() != reflect.String {
			return data, nil
		}
		if !t.Implements(reflect.TypeOf((*path.Path)(nil)).Elem()) {
			return data, nil
		}

		// Convert it
		return path.NewPath(data.(string)), nil
	}
}

func (m *Machine) defaultSyncedFolderType() (folderType *string, err error) {
	// Get all available synced folder plugins
	syncedFolders, err := m.project.basis.typeComponents(m.ctx, component.SyncedFolderType)
	if err != nil {
		return
	}

	// Get all plugin components
	syncedFoldersComponents := make([]*Component, 0, len(syncedFolders))
	for _, value := range syncedFolders {
		syncedFoldersComponents = append(syncedFoldersComponents, value)
	}

	// Sort by plugin priority. Higher is first
	// TODO: reintroduce priority
	// sort.SliceStable(syncedFoldersComponents, func(i, j int) bool {
	// 	return syncedFoldersComponents[i].Info.Priority > syncedFoldersComponents[j].Info.Priority
	// })

	// Remove unallowed types
	config := m.target.Configuration
	machineConfig := config.ConfigVm
	if machineConfig.AllowedSyncedFolderTypes != nil {
		// TODO
	}

	for _, component := range syncedFoldersComponents {
		syncedFolder := component.Value.(core.SyncedFolder)
		usable, err := syncedFolder.Usable(m)
		if err != nil {
			m.logger.Error("synced folder error on usable check",
				"plugin", component.Info.Name,
				"type", "SyncedFolder",
				"error", err)
			continue
		}
		if usable {
			return &component.Info.Name, nil
		}
	}
	return nil, fmt.Errorf("failed to detect guest plugin for current platform")
}

// SyncedFolders implements core.Machine
func (m *Machine) SyncedFolders() (folders []*core.MachineSyncedFolder, err error) {
	config := m.target.Configuration
	machineConfig := config.ConfigVm
	syncedFolders := machineConfig.SyncedFolders

	folders = []*core.MachineSyncedFolder{}
	for _, folder := range syncedFolders {
		folder.Type, err = m.defaultSyncedFolderType()
		if err != nil {
			return nil, err
		}
		lookup := "syncedfolder_" + *(folder.Type)
		v := m.cache.Get(lookup)
		if v == nil {
			plg, err := m.project.basis.component(m.ctx, component.SyncedFolderType, *folder.Type)
			if err != nil {
				return nil, err
			}

			v = plg.Value.(core.SyncedFolder)

			m.cache.Register(lookup, v)
		}

		if err = seedPlugin(v, m); err != nil {
			return nil, err
		}

		var f *core.Folder
		c := &mapstructure.DecoderConfig{
			DecodeHook: StringToPathFunc(),
			Result:     &f,
		}
		decoder, err := mapstructure.NewDecoder(c)
		if err != nil {
			return nil, err
		}
		err = decoder.Decode(folder)
		if err != nil {
			return nil, err
		}
		folders = append(folders, &core.MachineSyncedFolder{
			Plugin: v.(core.SyncedFolder),
			Folder: f,
		})
	}
	return
}

func (m *Machine) SaveMachine() (err error) {
	m.logger.Debug("saving machine to db", "machine", m.machine.Id)
	// Update the target record and uuid to match the machine's new state
	m.target.Record, err = anypb.New(m.machine)
	m.target.Uuid = m.machine.Id
	if err != nil {
		return nil
	}
	return m.Save()
}

func (m *Machine) toTarget() core.Target {
	return m
}

var _ core.Machine = (*Machine)(nil)
var _ core.Target = (*Machine)(nil)
