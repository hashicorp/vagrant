package plugin

import (
	"context"
	"testing"
	"time"

	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

func TestConfigPlugin_Attributes(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp, err := impl.ConfigAttributes()
	if err != nil {
		t.Fatalf("bad resp %s", err)
	}
	if resp[0] != "fubar" {
		t.Errorf("%s != fubar", resp[0])
	}
	if resp[1] != "foobar" {
		t.Errorf("%s != foobar", resp[1])
	}
}

func TestConfigPlugin_Load(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{}
	var resp map[string]interface{}
	resp, err = impl.ConfigLoad(context.Background(), data)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if _, ok := resp["test_key"]; !ok {
		t.Fatalf("bad resp content %#v", resp)
	}
	v := resp["test_key"].(string)
	if v != "test_val" {
		t.Errorf("%s != test_val", v)
	}
}

func TestConfigPlugin_Load_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{"pause": true}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Millisecond)
	defer cancel()
	n := make(chan struct{})
	go func() {
		_, err = impl.ConfigLoad(ctx, data)
		n <- struct{}{}
	}()
	<-n
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestConfigPlugin_Load_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{"pause": true}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	n := make(chan struct{})
	go func() {
		_, err = impl.ConfigLoad(ctx, data)
		n <- struct{}{}
	}()
	select {
	case <-n:
		t.Fatalf("unexpected completion")
	case <-time.After(2 * time.Millisecond):
		cancel()
	}
	<-n
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestConfigPlugin_Validate(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{}
	machine := &vagrant.Machine{}

	resp, err := impl.ConfigValidate(context.Background(), data, machine)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if len(resp) != 1 {
		t.Fatalf("bad size %d != 1", len(resp))
	}
	if resp[0] != "test error" {
		t.Errorf("%s != test error", resp[0])
	}
}

func TestConfigPlugin_Validate_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{"pause": true}
	machine := &vagrant.Machine{}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	n := make(chan struct{})
	go func() {
		_, err = impl.ConfigValidate(ctx, data, machine)
		n <- struct{}{}
	}()
	select {
	case <-n:
		t.Fatalf("unexpected completion")
	case <-time.After(2 * time.Millisecond):
		cancel()
	}
	<-n
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestConfigPlugin_Finalize(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{
		"test_key":  "test_val",
		"other_key": "other_val"}

	resp, err := impl.ConfigFinalize(context.Background(), data)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if _, ok := resp["test_key"]; !ok {
		t.Fatalf("bad resp content %#v", resp)
	}
	v := resp["test_key"].(string)
	if v != "test_val-updated" {
		t.Errorf("%s != test_val-updated", v)
	}
	v = resp["other_key"].(string)
	if v != "other_val-updated" {
		t.Errorf("%s != other_val-updated", v)
	}
}

func TestConfigPlugin_Finalize_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"configs": &ConfigPlugin{Impl: &MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("configs")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	data := map[string]interface{}{
		"pause":     true,
		"test_key":  "test_val",
		"other_key": "other_val"}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	n := make(chan struct{})
	go func() {
		_, err = impl.ConfigFinalize(ctx, data)
		n <- struct{}{}
	}()
	select {
	case <-n:
		t.Fatalf("unexpected completion")
	case <-time.After(2 * time.Millisecond):
		cancel()
	}
	<-n
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}
