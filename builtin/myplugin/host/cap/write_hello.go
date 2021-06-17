package cap

import (
	"io/ioutil"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHello(ui terminal.UI) error {
	msg := "Hello from the write hello capability, compliments of the AlwaysTrue Host"
	ui.Output(msg)
	data := []byte(msg)
	ioutil.WriteFile("/tmp/hello", data, 0644)
	return nil
}

func WriteHelloNoUI() error {
	msg := "Hello from the write hello capability, compliments of the AlwaysTrue Host"
	data := []byte(msg)
	ioutil.WriteFile("/tmp/hello", data, 0644)
	return nil
}
