// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package command

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

// Info is a Command implementation for myplugin.
// It is a subcommand of myplugin
type Host struct {
	*Command
}

// ExecuteFunc implements component.Command
func (c *Host) ExecuteFunc(cliArgs []string) interface{} {
	return c.Execute
}

// CommandInfoFunc implements component.Command
func (c *Host) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *Host) CommandInfo() (*component.CommandInfo, error) {
	return &component.CommandInfo{
		Name:     "host",
		Help:     c.Help(),
		Synopsis: c.Synopsis(),
		Flags:    c.Flags(),
	}, nil
}

func (c *Host) Synopsis() string {
	return "runs host capability"
}

func (c *Host) Help() string {
	return c.Synopsis()
}

func (c *Host) Flags() component.CommandFlags {
	return []*component.CommandFlag{}
}

func (c *Host) Execute(trm terminal.UI, project core.Project) int32 {
	trm.Output("Attempting to run capability on host plugin")

	h, err := project.Host()
	if err != nil {
		trm.Output("ERROR: %s", err)
		return 1
	}

	trm.Output("have host plugin to run against")

	if r, err := h.HasCapability("write_hello"); !r {
		trm.Output("No write_hello capability found (%s)", err)
		return 1
	}

	trm.Output("host plugin has write_hello capability to run")

	result, err := h.Capability("write_hello", trm)
	if err != nil {
		trm.Output("Error running capability: %s", err)
		return 1
	}

	trm.Output("Result: %#v", result)

	return 0
}

var (
	_ component.Command = (*Host)(nil)
)
