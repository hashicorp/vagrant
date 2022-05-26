package httpdownloader

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/builtin/httpdownloader/downloader"
)

//go:generate protoc -I ../../.. --go_opt=plugins=grpc --go_out=../../.. vagrant-ruby/builtin/httpdownloader/proto/plugin.proto

var PluginOptions = []sdk.Option{
	sdk.WithComponents(
		&downloader.Downloader{},
	),
	sdk.WithName("httpdownloader"),
}
