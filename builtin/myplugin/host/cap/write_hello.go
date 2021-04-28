package cap

import (
	"io/ioutil"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHelloFunc() interface{} {
	return WriteHello
}

func WriteHello(trm terminal.UI) error {
	trm.Output("Writing hello to /tmp/hello")

	data := []byte("hello from the always true host plugin\n")
	ioutil.WriteFile("/tmp/hello", data, 0644)
	return nil
}
