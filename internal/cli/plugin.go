// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package cli

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
)

type PluginCommand struct {
	*baseCommand
}

func (c *PluginCommand) Primary() bool {
	return false
}

func (c *PluginCommand) Run(args []string) int {
	plugin, ok := plugin.Builtins[args[0]]
	if !ok {
		panic("no such plugin: " + args[0])
	}

	// Run the plugin
	sdk.Main(plugin...)
	return 0
}

func (c *PluginCommand) Synopsis() string {
	return "Execute a built-in plugin."
}

func (c *PluginCommand) Help() string {
	return ""
}
