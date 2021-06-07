package otherplugin

import (
	"strings"

	"github.com/DavidGamba/go-getoptions/option"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	plugincore "github.com/hashicorp/vagrant-plugin-sdk/core"

	//	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	//"google.golang.org/protobuf/types/known/anypb"
)

type Command struct{}

func (c *Command) ExecuteFunc(cliArgs []string) interface{} {
	if len(cliArgs) < 2 {
		return c.ExecuteMain
	}
	switch cliArgs[1] {
	case "info":
		if len(cliArgs) < 3 {
			return c.ExecuteInfo
		}
		switch cliArgs[2] {
		case "ofni":
			return c.ExecuteOfni
		}
		return c.ExecuteInfo
	case "dothing":
		return c.ExecuteThing
	case "use-host":
		return c.ExecuteUseHostPlugin
	}
	return c.ExecuteMain
}

func (c *Command) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *Command) CommandInfo() *component.CommandInfo {
	return &component.CommandInfo{
		Name:     "otherplugin",
		Help:     "HELP MEEEEE!",
		Synopsis: "This command does stuff",
		Flags: []*option.Option{
			&option.Option{
				Name:        "thing",
				OptType:     option.StringType,
				Description: "a thing flag",
				DefaultStr:  "I'm a thing!",
			},
		},
		Subcommands: []*component.CommandInfo{
			&component.CommandInfo{
				Name:     "info",
				Help:     "Shows info",
				Synopsis: "IT. SHOWS. INFO.",
				Flags:    []*option.Option{},
				Subcommands: []*component.CommandInfo{
					&component.CommandInfo{
						Name:     "ofni",
						Help:     "Shows ofni",
						Synopsis: "BIZZARO info",
						Flags:    []*option.Option{},
					},
				},
			},
			&component.CommandInfo{
				Name:     "dothing",
				Help:     "Does thing",
				Synopsis: "Does this super great thing!",
				Flags: []*option.Option{
					&option.Option{
						OptType:     option.StringType,
						Name:        "stringflag",
						Description: "a test flag",
						DefaultStr:  "I'm a string!",
					},
				},
			},
			&component.CommandInfo{
				Name:     "use-host",
				Help:     "Executes a host capability",
				Synopsis: "Executes a host capability",
				Flags:    []*option.Option{},
			},
		},
	}
}

func (c *Command) ExecuteMain(trm terminal.UI, flags map[string]interface{}) int64 {
	trm.Output("You gave me the flag: " + flags["thing"].(string))

	trm.Output("My subcommands are: `info` and `dothing`")
	return 0
}

func (c *Command) ExecuteThing(trm terminal.UI, flags map[string]interface{}) int64 {
	trm.Output("Tricked ya! I actually do nothing :P")
	trm.Output("You gave me the stringflag: " + flags["stringflag"].(string))
	return 0
}

func (c *Command) ExecuteInfo(trm terminal.UI, p plugincore.Project, t plugincore.Target) int64 {
	mn, _ := p.MachineNames()
	trm.Output("\nMachines in this project")
	trm.Output(strings.Join(mn[:], "\n"))

	cwd, _ := p.CWD()
	datadir, _ := p.DataDir()
	vagrantfileName, _ := p.VagrantfileName()
	home, _ := p.Home()
	localDataPath, _ := p.LocalData()
	defaultPrivateKeyPath, _ := p.DefaultPrivateKey()

	trm.Output("\nEnvironment information")
	trm.Output("Working directory: " + cwd)
	if datadir != nil && datadir.DataDir() != nil {
		trm.Output("Data directory: " + datadir.DataDir().String())
	}
	trm.Output("Vagrantfile name: " + vagrantfileName)
	trm.Output("Home directory: " + home)
	trm.Output("Local data directory: " + localDataPath)
	trm.Output("Default private key path: " + defaultPrivateKeyPath)

	ptrm, err := p.UI()
	if err != nil {
		trm.Output("Failed to get project specific UI! Reason: " + err.Error())
	} else {
		ptrm.Output("YAY! This is project specific output!")
	}

	m, err := t.Specialize((*plugincore.Machine)(nil))
	if err != nil {
		trm.Output("Failed to specialize to machine! -- " + err.Error())
		return 1
	}

	machine := m
	trm.Output("successfully specialized to machine")
	id, err := machine.ID()
	if err != nil {
		trm.Output("failed to get machine id --> " + err.Error())
	} else {
		trm.Output("machine id is: " + id)
	}

	return 0
}

func (c *Command) ExecuteOfni(trm terminal.UI) int64 {
	trm.Output("I am bizzaro info! Call me ofni")
	return 0
}

func (c *Command) ExecuteUseHostPlugin(trm terminal.UI, host plugincore.Host) int64 {
	trm.Output("I'm going to use a the host plugin to do something!")
	ok := host.HasCapability("write_hello")
	if ok {
		trm.Output("Writing to file using `write_hello` capability")
		host.Capability("write_hello", argmapper.Typed(trm))
	} else {
		trm.Output("no `write_hello` capability found")
	}
	return 0
}
