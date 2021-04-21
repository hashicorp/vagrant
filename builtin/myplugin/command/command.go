package command

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

// ExecuteFunc implements component.Command
func (c *Command) ExecuteFunc([]string) interface{} {
	return c.Execute
}

// CommandInfoFunc implements component.Command
func (c *Command) CommandInfoFunc([]string) interface{} {
	return c.CommandInfo
}

func (c *Command) CommandInfo() *plugincore.CommandInfo {
	return &plugincore.CommandInfo{
		Name:        "myplugin",
		Help:        c.Help(),
		Synopsis:    c.Synopsis(),
		Flags:       c.Flags(),
		Subcommands: c.Subcommands(),
	}
}

func (c *Command) Synopsis() string {
	return "I don't do much, just hanging around"
}

func (c *Command) Help() string {
	return "I'm here for testing, try running some subcommands"
}

func (c *Command) Flags() []*option.Option {
	stringflag := option.New("hehe", option.StringType)
	stringflag.Description = "a test flag for strings"
	stringflag.DefaultStr = "message"
	stringflag.Aliases = append(stringflag.Aliases, "hh")

	return []*option.Option{stringflag}
}

func (c *Command) Subcommands() []*plugincore.CommandInfo {
	doThingCmd := &DoThing{Command: c}
	infoCmd := &Info{Command: c}
	return []*plugincore.CommandInfo{
		doThingCmd.CommandInfo(),
		infoCmd.CommandInfo(),
	}
}

func (c *Command) Execute(trm terminal.UI, flags map[string]interface{}) int64 {
	trm.Output("You gave me the flag: " + flags["hehe"].(string))

	trm.Output(c.Help())
	trm.Output("My subcommands are: ")
	for _, cmd := range c.Subcommands() {
		trm.Output("    " + cmd.Name)
	}
	return 0
}

var (
	_ component.Command = (*Command)(nil)
)
