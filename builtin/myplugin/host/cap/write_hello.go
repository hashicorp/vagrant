package cap

import (
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHello(ui terminal.UI) error {
	msg := "Hello from the write hello capability, compliments of the AlwaysTrue Host"
	ui.Output(msg)
	return nil
}
