package cap

import (
	"io/ioutil"
)

func WriteHelloFunc() interface{} {
	return WriteHello
}

// func WriteHello(trm terminal.UI) error {
func WriteHello() error {
	data := []byte("hello from the always true host plugin\n")
	ioutil.WriteFile("/tmp/hello", data, 0644)
	return nil
}
