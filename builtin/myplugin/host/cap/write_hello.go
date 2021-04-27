package cap

import (
	"io/ioutil"
)

func WriteHelloFunc() interface{} {
	return WriteHello
}

func WriteHello() {
	data := []byte("hello\ngo\n")
	ioutil.WriteFile("/tmp/dat1", data, 0644)
}
