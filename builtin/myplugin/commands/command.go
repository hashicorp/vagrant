package commands

import (
	"github.com/DavidGamba/go-getoptions/option"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	plugincore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/docs"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

type CommandConfig struct {
}

// Command is the Command implementation for myplugin.
type Command struct {
	config CommandConfig
}

func (c *Command) ConfigSet(v interface{}) error {
	return nil
}

func (c *Command) CommandFunc() interface{} {
	return nil
}

func (c *Command) Config() (interface{}, error) {
	return &c.config, nil
}

func (c *Command) Documentation() (*docs.Documentation, error) {
	doc, err := docs.New(docs.FromConfig(&CommandConfig{}))
	if err != nil {
		return nil, err
	}
	return doc, nil
}

// SynopsisFunc implements component.Command
func (c *Command) SynopsisFunc() interface{} {
	return c.Synopsis
}

// HelpFunc implements component.Command
func (c *Command) HelpFunc() interface{} {
	return c.Help
}

// FlagsFunc implements component.Command
func (c *Command) FlagsFunc() interface{} {
	return c.Flags
}

// ExecuteFunc implements component.Command
func (c *Command) ExecuteFunc() interface{} {
	return c.Execute
}

// SubcommandFunc implements component.Command
func (c *Command) SubcommandsFunc() interface{} {
	return c.Subcommands
}

// CommandInfoFunc implements component.Command
func (c *Command) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *Command) CommandInfo() *plugincore.CommandInfo {
	return &plugincore.CommandInfo{
		Name:     "myplugin",
		Help:     c.Help(),
		Synopsis: c.Synopsis(),
		Flags:    c.Flags(),
	}
}

func (c *Command) Synopsis() string {
	return "I don't do much, just hanging around"
}

func (c *Command) Help() string {
	return "I'm here for testing, try running some subcommands"
}

func (c *Command) Flags() []*option.Option {
	return []*option.Option{}
}

func (c *Command) Subcommands() []component.Command {
	return []component.Command{
		&DoThing{Command: c},
		&Info{Command: c},
	}
}

func (c *Command) Execute(trm terminal.UI) int64 {
	trm.Output(c.Help())
	return 0
}

var (
	_ component.Command = (*Command)(nil)
)
