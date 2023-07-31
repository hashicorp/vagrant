// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package host

import (
	"fmt"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/builtin/myplugin/host/cap"
)

type HostConfig struct {
}

// AlwaysTrueHost is a Host implementation for myplugin.
type AlwaysTrueHost struct {
	config HostConfig
}

func (c *AlwaysTrueHost) Seed(args ...interface{}) error {
	return nil
}

func (c *AlwaysTrueHost) Seeds() ([]interface{}, error) {
	return nil, nil
}

// DetectFunc implements component.Host
func (h *AlwaysTrueHost) HostDetectFunc() interface{} {
	return h.Detect
}

func (h *AlwaysTrueHost) Detect() bool {
	return true
}

// ParentFunc implements component.Host
func (h *AlwaysTrueHost) ParentFunc() interface{} {
	return h.Parent
}

func (h *AlwaysTrueHost) Parent() string {
	return ""
}

// HasCapabilityFunc implements component.Host
func (h *AlwaysTrueHost) HasCapabilityFunc() interface{} {
	return h.CheckCapability
}

func (h *AlwaysTrueHost) CheckCapability(n *component.NamedCapability) bool {
	if n.Capability == "write_hello" || n.Capability == "write_hello_file" {
		return true
	}
	return false
}

// CapabilityFunc implements component.Host
func (h *AlwaysTrueHost) CapabilityFunc(name string) interface{} {
	if name == "write_hello" {
		return h.WriteHelloCap
	} else if name == "write_hello_file" {
		return h.WriteHelloToTempFileCap
	}
	return fmt.Errorf("requested capability %s not found", name)
}

func (h *AlwaysTrueHost) WriteHelloCap(ui terminal.UI) error {
	return cap.WriteHello(ui)
}

func (h *AlwaysTrueHost) WriteHelloToTempFileCap() error {
	return cap.WriteHelloToTempfile()
}

var (
	_ component.Host = (*AlwaysTrueHost)(nil)
)
