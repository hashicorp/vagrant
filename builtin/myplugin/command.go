package myplugin

import (
	"strings"
	"time"

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
		Name:     []string{"myplugin"},
		Help:     c.Help(),
		Synopsis: c.Synopsis(),
		Flags:    c.Flags(),
	}
}

func (c *Command) Synopsis() string {
	return "I don't really do anything"
}

func (c *Command) Help() string {
	return "Output some project information!"
}

func (c *Command) Flags() []*option.Option {
	booltest := option.New("booltest", option.BoolType)
	booltest.Description = "a test flag for bools"
	booltest.DefaultStr = "true"
	booltest.Aliases = append(booltest.Aliases, "bt")

	stringflag := option.New("stringflag", option.StringType)
	stringflag.Description = "a test flag for strings"
	stringflag.DefaultStr = "message"
	stringflag.Aliases = append(stringflag.Aliases, "sf")

	return []*option.Option{booltest, stringflag}
}

func (c *Command) Subcommands() []string {
	return []string{}
}

func (c *Command) Execute(trm terminal.UI, env plugincore.Project) int64 {
	mn, _ := env.MachineNames()
	trm.Output("\nMachines in this project")
	trm.Output(strings.Join(mn[:], "\n"))

	cwd, _ := env.CWD()
	datadir, _ := env.DataDir()
	vagrantfileName, _ := env.VagrantfileName()
	home, _ := env.Home()
	localDataPath, _ := env.LocalData()
	defaultPrivateKeyPath, _ := env.DefaultPrivateKey()

	trm.Output("\nEnvironment information")
	trm.Output("Working directory: " + cwd)
	trm.Output("Data directory: " + datadir)
	trm.Output("Vagrantfile name: " + vagrantfileName)
	trm.Output("Home directory: " + home)
	trm.Output("Local data directory: " + localDataPath)
	trm.Output("Default private key path: " + defaultPrivateKeyPath)

	time.Sleep(1 * time.Second)

	return 0
}

var (
	_ component.Command = (*Command)(nil)
)
