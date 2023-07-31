// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package otherplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/builtin/otherplugin/guest"
)

var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		&guest.AlwaysTrueGuest{},
	),
	sdk.WithComponent(&Command{}, &component.CommandOptions{
		// Hide command from default help output
		Primary: false,
	}),
	sdk.WithName("otherplugin"),
}
