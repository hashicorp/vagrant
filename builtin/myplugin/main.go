package myplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/builtin/myplugin/command"
)

//go:generate protoc -I ../../.. --go_opt=plugins=grpc --go_out=../../.. vagrant-ruby/builtin/myplugin/plugin.proto

// Options are the SDK options to use for instantiation.
var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		&Provider{},
		[]component.Command{
			&command.Command{},
			&command.Info{},
			&command.DoThing{},
		},
	),
}
