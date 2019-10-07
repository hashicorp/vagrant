package vagrant

import (
	"testing"
)

func buildio() IOServer {
	return &IOSrv{
		Targets: map[string]chan (string){
			"stdout": make(chan string),
			"stderr": make(chan string)}}
}

func TestIOSrvWrite(t *testing.T) {
	iosrv := buildio()
	var i int
	go func() { i, _ = iosrv.Write("test string", "stdout") }()
	_, _ = iosrv.Read("stdout")
	if i != len("test string") {
		t.Fatalf("unexpected write bytes %d != %d",
			len("test string"), i)
	}
}

func TestIOSrvRead(t *testing.T) {
	iosrv := buildio()
	go func() { _, _ = iosrv.Write("test string", "stdout") }()
	r, _ := iosrv.Read("stdout")
	if r != "test string" {
		t.Fatalf("unexpected read result: %s", r)
	}
}

func TestIOSrvWriteBadTarget(t *testing.T) {
	iosrv := buildio()
	_, err := iosrv.Write("test string", "stdno")
	if err == nil {
		t.Fatalf("expected error on write")
	}
}

func TestIOSrvReadBadTarget(t *testing.T) {
	iosrv := buildio()
	_, err := iosrv.Read("stdno")
	if err == nil {
		t.Fatalf("expected error on read")
	}
}
