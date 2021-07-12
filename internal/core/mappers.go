package core

import (
	"strings"

	"github.com/DavidGamba/go-getoptions/option"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var Mappers = []interface{}{
	CommandArgToMap,
	FlagOption,
	JobCommandProto,
	OptionFlagProto,
}

func JobCommandProto(c *component.CommandInfo) []*vagrant_server.Job_Command {
	return jobCommandProto(c, []string{})
}

func FlagOption(input []*vagrant_server.Job_Flag) (opt []*option.Option, err error) {
	opt = []*option.Option{}
	for _, f := range input {
		var newOpt *option.Option
		switch f.Type {
		case vagrant_server.Job_Flag_STRING:
			newOpt = option.New(f.LongName, option.StringType)
		case vagrant_server.Job_Flag_BOOL:
			newOpt = option.New(f.LongName, option.BoolType)
		}
		newOpt.Description = f.Description
		newOpt.DefaultStr = f.DefaultValue
		opt = append(opt, newOpt)
	}
	return opt, err
}

func CommandArgToMap(input *vagrant_plugin_sdk.Command_Arguments) (map[string]interface{}, error) {
	result := make(map[string]interface{})
	for _, flg := range input.Flags {
		switch flg.Type {
		case vagrant_plugin_sdk.Command_Arguments_Flag_STRING:
			result[flg.Name] = flg.GetString_()
		case vagrant_plugin_sdk.Command_Arguments_Flag_BOOL:
			result[flg.Name] = flg.GetBool()
		}
	}
	return result, nil
}

func OptionFlagProto(input []*option.Option) []*vagrant_server.Job_Flag {
	output := []*vagrant_server.Job_Flag{}

	for _, f := range input {
		var flagType vagrant_server.Job_Flag_Type
		switch f.OptType {
		case option.StringType:
			flagType = vagrant_server.Job_Flag_STRING
		case option.BoolType:
			flagType = vagrant_server.Job_Flag_BOOL
		}

		// TODO: get aliases
		j := &vagrant_server.Job_Flag{
			LongName:     f.Name,
			ShortName:    f.Name,
			Description:  f.Description,
			DefaultValue: f.DefaultStr,
			Type:         flagType,
		}
		output = append(output, j)
	}
	return output
}

func jobCommandProto(c *component.CommandInfo, names []string) []*vagrant_server.Job_Command {
	names = append(names, c.Name)
	cmds := []*vagrant_server.Job_Command{
		{
			Name:     strings.Join(names, " "),
			Synopsis: c.Synopsis,
			Help:     c.Help,
			Flags:    OptionFlagProto(c.Flags),
		},
	}

	for _, scmd := range c.Subcommands {
		cmds = append(cmds, jobCommandProto(scmd, names)...)
	}
	return cmds
}
