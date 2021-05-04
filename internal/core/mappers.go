package core

import (
	"reflect"

	"github.com/DavidGamba/go-getoptions/option"
	"github.com/mitchellh/mapstructure"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func ProtoToFlagsMapper(input []*vagrant_server.Job_Flag) (opt []*option.Option, err error) {
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

func EnvironmentProto(input *Environment) (*vagrant_plugin_sdk.Args_Project, error) {
	var result vagrant_plugin_sdk.Args_Project
	pathToStringHook := func(f, t reflect.Type, data interface{}) (interface{}, error) {
		if f != reflect.TypeOf(path.NewPath(".")) {
			return data, nil
		}

		if t.Kind() != reflect.String {
			return data, nil
		}

		// Convert it
		path := data.(path.Path)
		return path.String(), nil
	}

	decoder, err := mapstructure.NewDecoder(
		&mapstructure.DecoderConfig{
			DecodeHook: pathToStringHook,
			Metadata:   nil,
			Result:     &result,
		},
	)
	if err != nil {
		return nil, err
	}
	return &result, decoder.Decode(input)
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

func FlagsToProtoMapper(input []*option.Option) []*vagrant_server.Job_Flag {
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

func HostComponentToProtoMapper(input Component) *vagrant_plugin_sdk.Args_Host {
	return &vagrant_plugin_sdk.Args_Host{
		ServerAddr: input.Info.ServerAddr,
	}
}
