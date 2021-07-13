package core

import (
	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

type Machine struct {
	*Target
}

// Close implements core.Machine
func (m *Machine) Close() (err error) {
	return
}

// ID implements core.Machine
func (m *Machine) ID() (id string, err error) {
	return m.target.Uuid, nil
}

// SetID implements core.Machine
func (m *Machine) SetID(value string) (err error) {
	m.target.Uuid = value
	return m.Save()
}

// Box implements core.Machine
func (m *Machine) Box() (b core.Box, err error) {
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
	return m.Save()
}

// Inspect implements core.Machine
func (m *Machine) Inspect() (printable string, err error) {
	return
}

// Reload implements core.Machine
func (m *Machine) Reload() (err error) {
	return
}

// ConnectionInfo implements core.Machine
func (m *Machine) ConnectionInfo() (info *core.ConnectionInfo, err error) {
	return
}

// MachineState implements core.Machine
func (m *Machine) MachineState() (state *core.MachineState, err error) {
	return
}

// SetMachineState implements core.Machine
func (m *Machine) SetMachineState(state *core.MachineState) (err error) {
	return
}

// UID implements core.Machine
func (m *Machine) UID() (userId int, err error) {
	return
}

// SyncedFolders implements core.Machine
func (m *Machine) SyncedFolders() (folders []core.SyncedFolder, err error) {
	return
}

var _ core.Machine = (*Machine)(nil)
var _ core.Target = (*Machine)(nil)
