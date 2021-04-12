package myplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
)

//go:generate protoc -I ../../.. --go_opt=plugins=grpc --go_out=../../.. vagrant-ruby/builtin/myplugin/plugin.proto

// Options are the SDK options to use for instantiation.
var Options = []sdk.Option{
	sdk.WithComponents(&Provider{}, &Command{}),
}
