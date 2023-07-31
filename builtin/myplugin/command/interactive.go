// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package command

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/docs"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

// Info is a Command implementation for myplugin.
// It is a subcommand of myplugin
type Interactive struct {
	*Command
}

func (c *Interactive) ConfigSet(v interface{}) error {
	return nil
}

func (c *Interactive) CommandFunc() interface{} {
	return nil
}

func (c *Interactive) Config() (interface{}, error) {
	return &c.config, nil
}

func (c *Interactive) Documentation() (*docs.Documentation, error) {
	doc, err := docs.New(docs.FromConfig(&CommandConfig{}))
	if err != nil {
		return nil, err
	}
	return doc, nil
}

// ExecuteFunc implements component.Command
func (c *Interactive) ExecuteFunc(cliArgs []string) interface{} {
	return c.Execute
}

// CommandInfoFunc implements component.Command
func (c *Interactive) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *Interactive) CommandInfo() (*component.CommandInfo, error) {
	return &component.CommandInfo{
		Name:     "interactive",
		Help:     c.Help(),
		Synopsis: c.Synopsis(),
		Flags:    c.Flags(),
	}, nil
}

func (c *Interactive) Synopsis() string {
	return "Test out interactive input"
}

func (c *Interactive) Help() string {
	return "Test out interactive input!"
}

func (c *Interactive) Flags() component.CommandFlags {
	return []*component.CommandFlag{}
}

func (c *Interactive) Execute(trm terminal.UI) int32 {
	output, err := trm.Input(&terminal.Input{Prompt: "\nWhat do you have to say: "})
	if err != nil {
		trm.Output("Error getting input")
		trm.Output(err.Error())
		return 1
	}
	trm.Output("Did you say " + output)

	output, err = trm.Input(&terminal.Input{Prompt: "\nTell me a secret: "})
	if err != nil {
		trm.Output("Error getting input")
		trm.Output(err.Error())
		return 1
	}
	trm.Output("Did you say " + output)
	return 0
}

var (
	_ component.Command = (*Interactive)(nil)
)
