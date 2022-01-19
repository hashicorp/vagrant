package core

import (
	"strings"

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

func FlagOption(input []*vagrant_server.Job_Flag) (opt component.CommandFlags, err error) {
	opt = make([]*component.CommandFlag, len(input))

	for i, f := range input {
		opt[i] = &component.CommandFlag{
			LongName:     f.LongName,
			ShortName:    f.ShortName,
			Description:  f.Description,
			DefaultValue: f.DefaultValue,
		}
		switch f.Type {
		case vagrant_server.Job_Flag_STRING:
			opt[i].Type = component.FlagString
		case vagrant_server.Job_Flag_BOOL:
			opt[i].Type = component.FlagBool
		}
	}
	return
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

func OptionFlagProto(input component.CommandFlags) []*vagrant_server.Job_Flag {
	output := make([]*vagrant_server.Job_Flag, len(input))

	for i, f := range input {
		output[i] = &vagrant_server.Job_Flag{
			LongName:     f.LongName,
			ShortName:    f.ShortName,
			Description:  f.Description,
			DefaultValue: f.DefaultValue,
		}
		switch f.Type {
		case component.FlagBool:
			output[i].Type = vagrant_server.Job_Flag_BOOL
		case component.FlagString:
			output[i].Type = vagrant_server.Job_Flag_STRING
		default:
			panic("unsupported flag type - " + f.Type.String())
		}
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
