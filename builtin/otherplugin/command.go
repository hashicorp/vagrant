// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package otherplugin

import (
	"strings"

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
		Flags: []*component.CommandFlag{
			{
				LongName:     "thing",
				Description:  "a thing flag",
				DefaultValue: "I'm a thing!",
				Type:         component.FlagString,
			},
		},
		Subcommands: []*component.CommandInfo{
			&component.CommandInfo{
				Name:     "info",
				Help:     "Shows info",
				Synopsis: "IT. SHOWS. INFO.",
				Flags:    []*component.CommandFlag{},
				Subcommands: []*component.CommandInfo{
					&component.CommandInfo{
						Name:     "ofni",
						Help:     "Shows ofni",
						Synopsis: "BIZZARO info",
						Flags:    []*component.CommandFlag{},
					},
				},
			},
			&component.CommandInfo{
				Name:     "dothing",
				Help:     "Does thing",
				Synopsis: "Does this super great thing!",
				Flags: []*component.CommandFlag{
					{
						LongName:     "stringflag",
						Description:  "a test flag",
						DefaultValue: "I'm a string!",
						Type:         component.FlagString,
					},
				},
			},
			&component.CommandInfo{
				Name:     "use-host",
				Help:     "Executes a host capability",
				Synopsis: "Executes a host capability",
				Flags:    []*component.CommandFlag{},
			},
		},
	}
}

func (c *Command) ExecuteMain(trm terminal.UI, flags map[string]interface{}) int32 {
	trm.Output("You gave me the flag: " + flags["thing"].(string))

	trm.Output("My subcommands are: `info` and `dothing`")
	return 0
}

func (c *Command) ExecuteThing(trm terminal.UI, flags map[string]interface{}) int32 {
	trm.Output("Tricked ya! I actually do nothing :P")
	trm.Output("You gave me the stringflag: " + flags["stringflag"].(string))
	return 0
}

func (c *Command) ExecuteInfo(trm terminal.UI, p plugincore.Project) int32 {
	mn, _ := p.TargetNames()
	trm.Output("\nMachines in this project")
	trm.Output(strings.Join(mn[:], "\n"))

	cwd, _ := p.CWD()
	datadir, _ := p.DataDir()
	vagrantfileName, _ := p.VagrantfileName()
	home, _ := p.Home()
	localDataPath, _ := p.LocalData()
	defaultPrivateKeyPath, _ := p.DefaultPrivateKey()

	trm.Output("\nEnvironment information")
	trm.Output("Working directory: " + cwd.String())
	if datadir != nil && datadir.DataDir() != nil {
		trm.Output("Data directory: " + datadir.DataDir().String())
	}
	trm.Output("Vagrantfile name: " + vagrantfileName)
	trm.Output("Home directory: " + home.String())
	trm.Output("Local data directory: " + localDataPath.String())
	trm.Output("Default private key path: " + defaultPrivateKeyPath.String())

	ptrm, err := p.UI()
	if err != nil {
		trm.Output("Failed to get project specific UI! Reason: " + err.Error())
	} else {
		ptrm.Output("YAY! This is project specific output!")
	}

	t, err := p.Target("one", "")
	if err != nil {
		trm.Output("Failed to load `one' target -- " + err.Error())
		return 1
	}

	m, err := t.Specialize((*plugincore.Machine)(nil))
	if err != nil {
		trm.Output("Failed to specialize to machine! -- " + err.Error())
		return 1
	}

	machine := m.(plugincore.Machine)
	trm.Output("successfully specialized to machine")
	id, err := machine.ID()
	if err != nil {
		trm.Output("failed to get machine id --> " + err.Error())
	} else {
		trm.Output("machine id is: " + id)
	}

	return 10
}

func (c *Command) ExecuteOfni(trm terminal.UI) int32 {
	trm.Output("I am bizzaro info! Call me ofni")
	return 0
}

func (c *Command) ExecuteUseHostPlugin(trm terminal.UI, basis plugincore.Basis) int32 {
	trm.Output("Requesting host plugin...")
	host, err := basis.Host()
	if err != nil {
		trm.Output("Error: Failed to receive host plugin - " + err.Error())
		return 1
	}
	trm.Output("Host plugin received. Checking for `write_hello` capability...")
	ok, err := host.HasCapability("write_hello")
	if err != nil {
		trm.Output("ERROR: " + err.Error())
		//	return 1
	}
	if ok {
		trm.Output("Found `write_hello` capability for host plugin, calling...")
		_, err = host.Capability("write_hello", trm)
		if err != nil {
			trm.Output("Error executing capability - " + err.Error())
			return 1
		}
	} else {
		trm.Output("no `write_hello` capability found")
	}

	return 0
}
