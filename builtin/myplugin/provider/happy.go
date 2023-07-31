// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package provider

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

// Happy is a provider that is just happy to be backing your vagrant VMs.
type Happy struct{}

func (p *Happy) Action(name string, args ...interface{}) error {
	return nil
}

// ActionFunc implements component.Provider
func (h *Happy) ActionFunc(actionName string) interface{} {
	return h.Action
}

func (h *Happy) Capability(name string, args ...interface{}) (interface{}, error) {
	return nil, nil
}

// CapabilityFunc implements component.Provider
func (h *Happy) CapabilityFunc(name string) interface{} {
	return h.Capability
}

func (h *Happy) HasCapability(n *component.NamedCapability) bool {
	return false
}

// HasCapabilityFunc implements component.Provicer
func (h *Happy) HasCapabilityFunc() interface{} {
	return h.HasCapability
}

func (h *Happy) MachineIdChanged() error {
	return nil
}

// MachineIdChangedFunc implements component.Provicer
func (h *Happy) MachineIdChangedFunc() interface{} {
	return h.MachineIdChanged
}

func (h *Happy) Installed(context.Context) (bool, error) {
	return true, nil
}

// InstalledFunc implements component.Provider
func (h *Happy) InstalledFunc() interface{} {
	return h.Installed
}

func (h *Happy) Init() (bool, error) {
	return true, nil
}

// InitFunc implements component.Provider
func (h *Happy) InitFunc() interface{} {
	return h.Init
}

func (h *Happy) SshInfo() (*core.SshInfo, error) {
	return nil, nil
}

// SshInfoFunc implements component.Provider
func (h *Happy) SshInfoFunc() interface{} {
	return h.SshInfo
}

func (h *Happy) State() (*core.MachineState, error) {
	return nil, nil
}

// StateFunc implements component.Provider
func (h *Happy) StateFunc() interface{} {
	return h.State
}

func (h *Happy) Usable() (bool, error) {
	return false, nil
}

// UsableFunc implements component.Provider
func (h *Happy) UsableFunc() interface{} {
	return h.Usable
}

var (
	_ component.Provider = (*Happy)(nil)
)
