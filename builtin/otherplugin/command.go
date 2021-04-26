package otherplugin

import (
	"strings"

	"github.com/DavidGamba/go-getoptions/option"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	plugincore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
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

func (c *Command) ExecuteInfo(trm terminal.UI, env plugincore.Project) int64 {
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

func (c *Command) ExecuteOfni(trm terminal.UI) int64 {
	trm.Output("I am bizzaro info! Call me ofni")
	return 0
}
