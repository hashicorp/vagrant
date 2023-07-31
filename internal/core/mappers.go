// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"strings"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
)

var Mappers = []interface{}{
	JobCommandProto,
}

// JobCommandProto converts a CommandInfo into its proto equivalent
func JobCommandProto(c *component.CommandInfo) []*vagrant_plugin_sdk.Command_CommandInfo {
	return jobCommandProto(c, []string{})
}

func jobCommandProto(c *component.CommandInfo, names []string) []*vagrant_plugin_sdk.Command_CommandInfo {
	names = append(names, c.Name)
	flgs, _ := protomappers.FlagsProto(c.Flags)
	cmds := []*vagrant_plugin_sdk.Command_CommandInfo{
		{
			Name:     strings.Join(names, " "),
			Synopsis: c.Synopsis,
			Help:     c.Help,
			Flags:    flgs,
		},
	}

	for _, scmd := range c.Subcommands {
		cmds = append(cmds, jobCommandProto(scmd, names)...)
	}
	return cmds
}
