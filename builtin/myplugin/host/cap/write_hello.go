package cap

import (
	"io/ioutil"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHelloFunc() interface{} {
	return WriteHello
}

func WriteHello(trm terminal.UI) {
	data := []byte("hello\ngo\n")
	ioutil.WriteFile("/tmp/dat1", data, 0644)
}
