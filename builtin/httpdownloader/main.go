// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package httpdownloader

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/builtin/httpdownloader/downloader"
)

//go:generate stringer -type=HTTPMethod -linecomment ./downloader

var PluginOptions = []sdk.Option{
	sdk.WithComponents(
		&downloader.Downloader{},
	),
	sdk.WithName("httpdownloader"),
}
