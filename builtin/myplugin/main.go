package myplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/builtin/myplugin/command"
	communincator "github.com/hashicorp/vagrant/builtin/myplugin/communicator"
	"github.com/hashicorp/vagrant/builtin/myplugin/host"
	"github.com/hashicorp/vagrant/builtin/myplugin/push"
)

//go:generate protoc -I ../../.. --go_opt=plugins=grpc --go_out=../../.. vagrant-ruby/builtin/myplugin/proto/plugin.proto

// Options are the SDK options to use for instantiation.
var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		// &Provider{},
		&command.Command{},
		&host.AlwaysTrueHost{},
		&communincator.DummyCommunicator{},
		&push.Encouragement{},
	),
	sdk.WithMappers(StructToCommunincatorOptions),
	sdk.WithName("myplugin"),
}
