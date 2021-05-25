package core

import (
	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

type Machine struct {
	*Target
}

func (m *Machine) Close() (err error) {
	return
}

func (m *Machine) ID() (id string, err error) {
	return "machine-id-value", nil
}

func (m *Machine) SetID(value string) (err error) {
	return
}

func (m *Machine) Box() (b core.Box, err error) {
	return
}

func (m *Machine) Guest() (g core.Guest, err error) {
	return
}

func (m *Machine) IndexUUID() (id string, err error) {
	return
}

func (m *Machine) SetUUID(id string) (err error) {
	return
}

func (m *Machine) Inspect() (printable string, err error) {
	return
}

func (m *Machine) Reload() (err error) {
	return
}

func (m *Machine) ConnectionInfo() (info *core.ConnectionInfo, err error) {
	return
}

func (m *Machine) MachineState() (state *core.MachineState, err error) {
	return
}

func (m *Machine) SetMachineState(state *core.MachineState) (err error) {
	return
}

func (m *Machine) UID() (userId int, err error) {
	return
}

func (m *Machine) SyncedFolders() (folders []core.SyncedFolder, err error) {
	return
}

var _ core.Machine = (*Machine)(nil)
var _ core.Target = (*Machine)(nil)
