package core

import (
	"reflect"

	"github.com/golang/protobuf/ptypes"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Machine struct {
	*Target
	machine *vagrant_server.Target_Machine
	logger  hclog.Logger
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
	return m.SaveMachine()
}

// Box implements core.Machine
func (m *Machine) Box() (b core.Box, err error) {
	// TODO: need Vagrantfile
	return
}

// Guest implements core.Machine
func (m *Machine) Guest() (g core.Guest, err error) {
	// TODO: need Vagrantfile + communicator
	return
}

func (m *Machine) GetUUID() (id string, err error) {
	return m.target.Uuid, nil
}

// SetUUID implements core.Machine
func (m *Machine) SetUUID(id string) (err error) {
	m.target.Uuid = id
	return m.SaveMachine()
}

// Inspect implements core.Machine
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
	// TODO: need provider
	return
}

// SetMachineState implements core.Machine
func (m *Machine) SetMachineState(state *core.MachineState) (err error) {
	// TODO: maybe this should come from the machine
	s := vagrant_server.Operation_PhysicalState_value[state.ID]
	m.target.State = vagrant_server.Operation_PhysicalState(s)
	return m.SaveMachine()
}

func (m *Machine) UID() (userId string, err error) {
	return m.machine.Uid, nil
}

// SyncedFolders implements core.Machine
func (m *Machine) SyncedFolders() (folders []core.SyncedFolder, err error) {
	return
}

func (m *Machine) SaveMachine() (err error) {
	m.logger.Debug("saving machine to db", "machine", m.machine.Id)
	m.target.Record, err = ptypes.MarshalAny(m.machine)
	if err != nil {
		return nil
	}
	return m.Save()
}

var _ core.Machine = (*Machine)(nil)
var _ core.Target = (*Machine)(nil)
