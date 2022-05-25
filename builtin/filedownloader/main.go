package filedownloader

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/builtin/filedownloader/downloader"
)

//go:generate protoc -I ../../.. --go_opt=plugins=grpc --go_out=../../.. vagrant-ruby/builtin/filedownloader/proto/plugin.proto

var PluginOptions = []sdk.Option{
	sdk.WithComponents(
		&downloader.Downloader{},
	),
	sdk.WithName("filedownloader"),
}
