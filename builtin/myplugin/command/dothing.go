package command

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/docs"
	"github.com/hashicorp/vagrant-plugin-sdk/localizer"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/builtin/myplugin/locales"
	"golang.org/x/text/language"
)

// DoThing is a Command implementation for myplugin
// It is a subcommand of myplugin
type DoThing struct {
	*Command
}

func (c *DoThing) ConfigSet(v interface{}) error {
	return nil
}

func (c *DoThing) CommandFunc() interface{} {
	return nil
}

func (c *DoThing) Config() (interface{}, error) {
	return &c.config, nil
}

func (c *DoThing) Documentation() (*docs.Documentation, error) {
	doc, err := docs.New(docs.FromConfig(&CommandConfig{}))
	if err != nil {
		return nil, err
	}
	return doc, nil
}

// ExecuteFunc implements component.Command
func (c *DoThing) ExecuteFunc([]string) interface{} {
	return c.Execute
}

// CommandInfoFunc implements component.Command
func (c *DoThing) CommandInfoFunc() interface{} {
	return c.CommandInfo
}

func (c *DoThing) CommandInfo() (*component.CommandInfo, error) {
	return &component.CommandInfo{
		Name:     "dothing",
		Help:     c.Help(),
		Synopsis: c.Synopsis(),
		Flags:    c.Flags(),
	}, nil
}

func (c *DoThing) Synopsis() string {
	return "Really important *stuff*"
}

func (c *DoThing) Help() string {
	return "Usage: vagrant myplugin dothing"
}

func (c *DoThing) Flags() component.CommandFlags {
	return []*component.CommandFlag{
		{
			LongName:     "booltest",
			ShortName:    "b",
			Description:  "test flag for bools",
			DefaultValue: "true",
			Type:         component.FlagBool,
		},
		{
			LongName:     "stringflag",
			ShortName:    "s",
			Description:  "test flag for strings",
			DefaultValue: "a default message value",
			Type:         component.FlagString,
		},
		{
			LongName:     "spanish",
			ShortName:    "e",
			Description:  "make messages spanish",
			DefaultValue: "false",
			Type:         component.FlagBool,
		},
	}
}

func (c *DoThing) Execute(trm terminal.UI, params *component.CommandParams) int32 {
	isSpanish := false
	if val, ok := params.Flags["spanish"]; ok {
		isSpanish = val.(bool)
	}
	var l *localizer.Localizer
	if isSpanish {
		localeData, err := locales.Asset("locales/assets/es.json")
		if err != nil {
			return 1
		}
		l, err = localizer.NewPluginLocalizer(language.Spanish, localeData, "locales/assets/es.json", trm)
		if err != nil {
			return 1
		}
	} else {
		localeData, err := locales.Asset("locales/assets/en.json")
		if err != nil {
			return 1
		}
		l, err = localizer.NewPluginLocalizer(language.English, localeData, "locales/assets/en.json", trm)
		if err != nil {
			return 1
		}
	}
	l.Output("dothing", nil)
	return 0
}

var (
	_ component.Command = (*DoThing)(nil)
)
