package cap

import (
	"io/ioutil"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHelloFunc() interface{} {
	return WriteHello
}

func WriteHello(trm terminal.UI) error {
	trm.Output("Writing to /tmp/dat1")

	data := []byte("hello\ngo\n")
	ioutil.WriteFile("/tmp/dat1", data, 0644)
	return nil
}
