package vagrant

import (
	"strings"
	"testing"
)

func TestLoadEnvironment(t *testing.T) {
	env, err := LoadEnvironment("{}", nil)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	if env.UI == nil {
		t.Fatalf("no UI configured for environment")
	}
}

func TestBadLoadEnvironment(t *testing.T) {
	_, err := LoadEnvironment("ack", nil)
	if err == nil {
		t.Fatalf("expected load error but none provided")
	}
}

func TestLoadEnvironmentUIStdout(t *testing.T) {
	iosrv := buildio()
	env, err := LoadEnvironment("{}", iosrv)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	go func() { env.UI.Info("test string") }()
	str := <-iosrv.Streams()["stdout"]
	if !strings.Contains(str, "test string") {
		t.Fatalf("unexpected output: %s", str)
	}
}

func TestLoadEnvironmentUIStderr(t *testing.T) {
	iosrv := buildio()
	env, err := LoadEnvironment("{}", iosrv)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	go func() { env.UI.Error("test string") }()
	str, err := iosrv.Read("stderr")
	if !strings.Contains(str, "test string") {
		t.Fatalf("unexpected output: %s", str)
	}
}

func TestDumpEnvironment(t *testing.T) {
	env, err := LoadEnvironment("{}", nil)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	d, err := DumpEnvironment(env)
	if err != nil {
		t.Fatalf("unexpected dump error: %s", err)
	}
	if d != "{}" {
		t.Fatalf("unexpected dump information: %s", d)
	}
}
