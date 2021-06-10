package cap

import (
	"io/ioutil"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHello(ui terminal.UI) error {
	data := []byte("Hello from the write hello capability, compliments of the AlwaysTrue Host")
	ioutil.WriteFile("/tmp/hello", data, 0644)
	return nil
}
