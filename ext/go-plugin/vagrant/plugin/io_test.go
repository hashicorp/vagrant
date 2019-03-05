package plugin

import (
	"testing"

	"github.com/hashicorp/go-plugin"
)

type MockIO struct {
	Core
}

func TestIO_ReadWrite(t *testing.T) {
	ioplugin := &MockIO{}
	ioplugin.Init()
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"io": &IOPlugin{Impl: ioplugin}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("io")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(IO)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}
	go func() {
		length, err := impl.Write("test_message", "stdout")
		if err != nil {
			t.Fatalf("bad write: %s", err)
		}
		if length != len("test_message") {
			t.Fatalf("bad length %d != %d", length, len("test_message"))
		}
	}()
	resp, err := impl.Read("stdout")
	if err != nil {
		t.Fatalf("bad read: %s", err)
	}
	if resp != "test_message" {
		t.Errorf("%s != test_message", resp)
	}
}

func TestIO_Write_bad(t *testing.T) {
	ioplugin := &MockIO{}
	ioplugin.Init()
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"io": &IOPlugin{Impl: ioplugin}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("io")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(IO)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}
	_, err = impl.Write("test_message", "bad-target")
	if err == nil {
		t.Fatalf("illegal write")
	}
}

func TestIO_Read_bad(t *testing.T) {
	ioplugin := &MockIO{}
	ioplugin.Init()
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"io": &IOPlugin{Impl: ioplugin}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("io")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(IO)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}
	_, err = impl.Read("bad-target")
	if err == nil {
		t.Fatalf("illegal read")
	}
}
