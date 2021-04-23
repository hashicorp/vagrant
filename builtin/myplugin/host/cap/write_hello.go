package cap

import "io/ioutil"

func WriteHello() {
	data := []byte("hello\ngo\n")
	ioutil.WriteFile("/tmp/dat1", data, 0644)
}
