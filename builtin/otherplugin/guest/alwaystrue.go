// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package guest

import (
	"errors"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	plugincore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/builtin/otherplugin/guest/cap"
)

type GuestConfig struct {
}

// AlwaysTrueGuest is a Guest implementation for myplugin.
type AlwaysTrueGuest struct {
	config GuestConfig
}

func (c *AlwaysTrueGuest) Seed(args ...interface{}) error {
	return nil
}

func (c *AlwaysTrueGuest) Seeds() ([]interface{}, error) {
	return nil, nil
}

// DetectFunc implements component.Guest
func (h *AlwaysTrueGuest) GuestDetectFunc() interface{} {
	return h.Detect
}

func (h *AlwaysTrueGuest) Detect(t plugincore.Target) bool {
	m, err := t.Specialize((*plugincore.Machine)(nil))
	if err != nil {
		return false
	}
	machine := m.(plugincore.Machine)
	machine.ConnectionInfo()
	// TODO: need a communicator to connect to guest
	return true
}

// ParentsFunc implements component.Guest
func (h *AlwaysTrueGuest) ParentFunc() interface{} {
	return h.Parent
}

func (h *AlwaysTrueGuest) Parent() string {
	return ""
}

// HasCapabilityFunc implements component.Guest
func (h *AlwaysTrueGuest) HasCapabilityFunc() interface{} {
	return h.CheckCapability
}

func (h *AlwaysTrueGuest) CheckCapability(n *component.NamedCapability) bool {
	if n.Capability == "hello" {
		return true
	}
	return false
}

// CapabilityFunc implements component.Guest
func (h *AlwaysTrueGuest) CapabilityFunc(name string) interface{} {
	if name == "hello" {
		return h.WriteHelloCap
	}
	return errors.New("invalid capability requested")
}

func (h *AlwaysTrueGuest) WriteHelloCap(m plugincore.Machine) error {
	return cap.WriteHello(m)
}

var (
	_ component.Guest = (*AlwaysTrueGuest)(nil)
)
