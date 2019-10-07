package vagrant

import (
	"errors"
)

type StreamIO interface {
	Read(target string) (content string, err error)
	Write(content, target string) (n int, err error)
}

type IOServer interface {
	Streams() map[string]chan (string)
	StreamIO
}

type IOSrv struct {
	Targets map[string]chan (string)
}

func (i *IOSrv) Streams() map[string]chan (string) {
	return i.Targets
}

type IOWriter struct {
	target string
	srv    IOServer
}

func (i *IOWriter) Write(b []byte) (n int, err error) {
	content := string(b)
	n, err = i.srv.Write(content, i.target)
	return
}

func (i *IOSrv) Read(target string) (content string, err error) {
	if _, ok := i.Streams()[target]; !ok {
		err = errors.New("Unknown target defined")
		return
	}
	content = <-i.Streams()[target]
	return
}

func (i *IOSrv) Write(content, target string) (n int, err error) {
	if _, ok := i.Streams()[target]; !ok {
		err = errors.New("Unknown target defined")
		return
	}
	i.Streams()[target] <- content
	n = len(content)
	return
}
