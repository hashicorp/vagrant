// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package cli

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/version"
)

type VersionCommand struct {
	*baseCommand

	VersionInfo *version.VersionInfo
}

func (c *VersionCommand) Run(args []string) int {
	flagSet := c.Flags()

	// Initialize. If we fail, we just exit since Init handles the UI.
	if err := c.Init(
		WithArgs(args),
		WithFlags(flagSet),
		WithNoConfig(),
		WithClient(false),
	); err != nil {
		return 1
	}

	out := c.VersionInfo.FullVersionNumber(true)
	c.ui.Output(out)

	return 0
}

func (c *VersionCommand) Flags() component.CommandFlags {
	return c.flagSet(0, nil)
}

func (c *VersionCommand) Primary() bool {
	return true
}

// func (c *VersionCommand) AutocompleteArgs() complete.Predictor {
// 	return complete.PredictNothing
// }

// func (c *VersionCommand) AutocompleteFlags() complete.Flags {
// 	return c.Flags().Completions()
// }

func (c *VersionCommand) Synopsis() string {
	return "Prints the version of this Vagrant CLI"
}

func (c *VersionCommand) Help() string {
	return formatHelp(`
Usage: vagrant version
  Prints the version of this Vagrant CLI.

  There are no arguments or flags to this command. Any additional arguments or
  flags are ignored.
`)
}
