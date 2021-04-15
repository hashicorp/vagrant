package commands

import (
	"strings"

	"github.com/DavidGamba/go-getoptions/option"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	plugincore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/docs"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

// Info is a Command implementation for myplugin.
// It is a subcommand of myplugin
type Info struct {
	*Command
}

func (c *Info) ConfigSet(v interface{}) error {
	return nil
}

func (c *Info) CommandFunc() interface{} {
	return nil
}

func (c *Info) Config() (interface{}, error) {
	return &c.config, nil
}

func (c *Info) Documentation() (*docs.Documentation, error) {
	doc, err := docs.New(docs.FromConfig(&CommandConfig{}))
	if err != nil {
		return nil, err
	}
	return doc, nil
}

// ExecuteFunc implements component.Command
func (c *Info) ExecuteFunc() interface{} {
	return c.Execute
}

// CommandInfoFunc implements component.Command
func (c *Info) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *Info) CommandInfo() *plugincore.CommandInfo {
	return &plugincore.CommandInfo{
		Name:     "info",
		Help:     c.Help(),
		Synopsis: c.Synopsis(),
		Flags:    c.Flags(),
	}
}

func (c *Info) Synopsis() string {
	return "Output some project information!"
}

func (c *Info) Help() string {
	return "Output some project information!"
}

func (c *Info) Flags() []*option.Option {
	return []*option.Option{}
}

func (c *Info) Execute(trm terminal.UI, env plugincore.Project) int64 {
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

	return 0
}

var (
	_ component.Command = (*Command)(nil)
)
