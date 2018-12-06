package vagrant

import (
	"strings"
	"testing"
)

func TestMachineLoad(t *testing.T) {
	_, err := LoadMachine("{}", nil)
	if err != nil {
		t.Fatalf("failed to load machine: %s", err)
	}
}

func TestMachineDump(t *testing.T) {
	m, err := LoadMachine("{}", nil)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	_, err = DumpMachine(m)
	if err != nil {
		t.Fatalf("failed to dump machine: %s", err)
	}
}

func TestMachineUI(t *testing.T) {
	iosrv := buildio()
	m, err := LoadMachine("{}", iosrv)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	go func() { m.UI.Info("test string") }()
	r, _ := iosrv.Read("stdout")
	if !strings.Contains(r, "test string") {
		t.Fatalf("unexpected read result: %s", r)
	}
}

func TestMachineUINamed(t *testing.T) {
	iosrv := buildio()
	m, err := LoadMachine("{\"name\":\"plugintest\"}", iosrv)
	if err != nil {
		t.Fatalf("unexpected load error: %s", err)
	}
	go func() { m.UI.Info("test string") }()
	r, _ := iosrv.Read("stdout")
	if !strings.Contains(r, "test string") {
		t.Fatalf("unexpected read result: %s", r)
	}
	if !strings.Contains(r, "plugintest") {
		t.Fatalf("output does not contain name: %s", r)
	}
}
