package myplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/builtin/myplugin/command"
	"github.com/hashicorp/vagrant/builtin/myplugin/host"
)

//go:generate protoc -I ../../.. --go_opt=plugins=grpc --go_out=../../.. vagrant-ruby/builtin/myplugin/plugin.proto

// Options are the SDK options to use for instantiation.
var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		&Provider{},
		&command.Command{},
		&host.AlwaysTrueHost{},
		&DummyCommunicator{},
	),
	sdk.WithName("myplugin"),
}
