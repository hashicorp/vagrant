package core

import (
	"fmt"
	"reflect"

	"github.com/golang/protobuf/ptypes"
	"github.com/mitchellh/mapstructure"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Machine struct {
	*Target
	box     *Box
	machine *vagrant_server.Target_Machine
	logger  hclog.Logger
	guest   core.Guest
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
	if value == "" {
		err = m.Destroy()
		if err != nil {
			return err
		}
		m.machine.Id = value
	} else {
		m.machine.Id = value
		return m.SaveMachine()
	}
	return
}

func (m *Machine) Box() (b core.Box, err error) {
	if m.box == nil {
		// TODO: get provider info here too/generate full machine config?
		// We know that these are machines so, save the Machine record
		boxes, _ := m.project.Boxes()
		boxName := m.Config().ConfigVm.Box
		// Get the first provider available - that's the one that
		// will be used to launch the machine
		provider := m.Config().ConfigVm.Providers[0].Type
		b, err := boxes.Find(boxName, "", provider)
		if err != nil {
			return nil, err
		}
		if b == nil {
			// Add the box
			b, err = addBox(boxName, provider, m.project.basis)
			if err != nil {
				return nil, err
			}
		}
		m.machine.Box = b.(*Box).ToProto()
		m.Save()
		m.box = b.(*Box)
	}

	return m.box, nil
}

// Guest implements core.Machine
func (m *Machine) Guest() (g core.Guest, err error) {
	// Try to see if a guest has already been found
	if m.guest != nil {
		return m.guest, nil
	}

	// Check if a guest is provided by the Vagrantfile. If it is, then try
	// to use that guest
	// TODO: This check maybe needs to get reworked when the Vagrantfile bits
	// actually start getting used
	if m.target.Configuration.ConfigVm.Guest != "" {
		// Ignore error about guest not being found - will also try detecting the guest
		guest, _ := m.project.basis.component(
			m.ctx, component.GuestType, m.target.Configuration.ConfigVm.Guest)
		if guest != nil {
			m.guest = guest.Value.(core.Guest)
			m.seedPlugin(m.guest)
			return m.guest, nil
		}
	}

	// Try to detect a guest
	guests, err := m.project.basis.typeComponents(m.ctx, component.GuestType)
	if err != nil {
		return
	}

	var result core.Guest
	var result_name string
	var numParents int

	for name, g := range guests {
		guest := g.Value.(core.Guest)
		detected, err := guest.Detect(m.toTarget())
		if err != nil {
			m.logger.Error("guest error on detection check",
				"plugin", name,
				"type", "Guest",
				"error", err)

			continue
		}
		if result == nil {
			if detected {
				result = guest
				result_name = name
				numParents = g.plugin.ParentCount()
			}
			continue
		}

		if detected {
			gp := g.plugin.ParentCount()

			if gp > numParents {
				result = guest
				result_name = name
				numParents = gp
			}
		}
	}

	if result == nil {
		return nil, fmt.Errorf("failed to detect guest plugin for current platform")
	}

	m.logger.Info("guest detection complete",
		"name", result_name)

	// NOTE: For guest seeding we need to prevent guest plugin instance
	// from being cached and reused. Currently, in a multi-machine setup
	// which are the same guest, the target values will get appended
	// TODO(spox): Fix this in the plugin manager
	m.seedPlugin(result)
	m.guest = result
	return result, nil
}

func (m *Machine) seedPlugin(plg interface{}) (err error) {
	if s, ok := plg.(core.Seeder); ok {
		seeds, err := s.Seeds()
		if err != nil {
			return err
		}
		seeds.Typed = append(seeds.Typed, m.Target)
		if err = s.Seed(seeds); err != nil {
			return err
		}
	}
	return
}

func (m *Machine) Inspect() (printable string, err error) {
	name, err := m.Name()
	provider, err := m.Provider()
	printable = "#<" + reflect.TypeOf(m).String() + ": " + name + " (" + reflect.TypeOf(provider).String() + ")>"
	return
}

// Reload implements core.Machine
func (m *Machine) Reload() (err error) {
	// TODO
	return
}

// ConnectionInfo implements core.Machine
func (m *Machine) ConnectionInfo() (info *core.ConnectionInfo, err error) {
	// TODO: need Vagrantfile
	return
}

// MachineState implements core.Machine
func (m *Machine) MachineState() (state *core.MachineState, err error) {
	var result core.MachineState
	return &result, mapstructure.Decode(m.machine.State, &result)
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

// SyncedFolders implements core.Machine
func (m *Machine) SyncedFolders() (folders []*core.MachineSyncedFolder, err error) {
	config := m.target.Configuration
	machineConfig := config.ConfigVm
	syncedFolders := machineConfig.SyncedFolders

	folders = []*core.MachineSyncedFolder{}
	for _, folder := range syncedFolders {
		// TODO: get default synced folder type
		folder.Type = "virtualbox"
		plg, err := m.project.basis.component(m.ctx, component.SyncedFolderType, folder.Type)
		if err != nil {
			return nil, err
		}
		m.seedPlugin(plg.Value)
		var f *core.Folder
		mapstructure.Decode(folder, &f)
		folders = append(folders, &core.MachineSyncedFolder{
			Plugin: plg.Value.(core.SyncedFolder),
			Folder: f,
		})
	}
	return
}

func (m *Machine) SaveMachine() (err error) {
	m.logger.Debug("saving machine to db", "machine", m.machine.Id)
	m.target.Record, err = ptypes.MarshalAny(m.machine)
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
