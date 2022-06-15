package configvagrant

import (
	"fmt"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		&Config{},
		&Command{},
	),
	sdk.WithName("configvagrant"),
}

type Vagrant struct {
	Sensitive []string `hcl:"sensitive,optional" json:",omitempty"`
	Host      *string  `hcl:"host,optional" json:"host,omitempty"`
	Plugins   []Plugin `hcl:"plugins,block" json:"plugins,omitempty"`
}

type Plugin struct {
	Name string `hcl:"name,label"`

	EntryPoint *string  `hcl:"entry_point,optional" json:"entry_point,omitempty"`
	Sources    []string `hcl:"sources,optional" json:"source,omitempty"`
	Version    *string  `hcl:"version,optional" json:"version,omitempty"`
}

type Config struct{}

func (c *Config) Register() (*component.ConfigRegistration, error) {
	return &component.ConfigRegistration{
		Identifier: "vagrants",
	}, nil
}

func (c *Config) StructFunc() interface{} {
	return c.Struct
}

func (c *Config) Struct() *Vagrant {
	return &Vagrant{}
}

func (c *Config) MergeFunc() interface{} {
	return c.Merge
}

func (c *Config) Merge(input struct {
	argmapper.Struct

	Log     hclog.Logger `argmapper:",typeOnly"`
	Base    *component.ConfigData
	ToMerge *component.ConfigData
}) (*component.ConfigData, error) {
	input.Log.Info("merging config values for the vagrants namespace")
	result := &component.ConfigData{
		Data: map[string]interface{}{},
	}

	for k, v := range input.Base.Data {
		input.Log.Info("Base value", "key", k, "value", v)
		result.Data[k] = v
	}

	for k, v := range input.ToMerge.Data {
		input.Log.Info("Merged value", "key", k, "value", v, "pre-existing", result.Data[k])
		if v == result.Data[k] {
			return nil, fmt.Errorf("values for merge should not match (%#v == %#v)", v, result.Data[k])
		}
		result.Data[k] = v
	}

	return result, nil
}

func (c *Config) FinalizeFunc() interface{} {
	return c.Finalize
}

func (c *Config) Finalize(d *component.ConfigData) (*component.ConfigData, error) {
	return d, nil
}

type Command struct{}

func (c *Command) ExecuteFunc(_ []string) interface{} {
	return c.Execute
}

func (c *Command) Execute(ui terminal.UI, v core.Vagrantfile) int32 {
	ui.Output("Checking for our defined config...")
	ui.Output("Our vagrantfile value is: %#v", v)
	conf, err := v.GetConfig("vagrants")
	if err != nil {
		ui.Output("failed to get configuration for 'vagrants' namespace: %q", err)
		return 1
	}

	ui.Output("We got something here!")
	ui.Output("Config defined host: %s", conf.Data["host"])
	return 0
}

func (c *Command) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *Command) CommandInfo() *component.CommandInfo {
	return &component.CommandInfo{
		Name: "configvagrant",
		Help: "I display config",
	}
}
