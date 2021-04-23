package otherplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
)

var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		&Command{},
	),
}
