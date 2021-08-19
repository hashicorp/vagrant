package otherplugin

import (
	sdk "github.com/hashicorp/vagrant-plugin-sdk"
	"github.com/hashicorp/vagrant/builtin/otherplugin/guest"
)

var CommandOptions = []sdk.Option{
	sdk.WithComponents(
		&Command{},
		&guest.AlwaysTrueGuest{},
	),
	sdk.WithName("otherplugin"),
}
