package main

import (
	"encoding/json"
	"testing"

	"github.com/hashicorp/go-plugin"
	vplugin "github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

func TestConfig_Load(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"config": &vplugin.ConfigPlugin{Impl: &vplugin.MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("config")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteConfig{
		Config: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	data := map[string]string{"test_key": "custom_val"}
	s, err := json.Marshal(data)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	result := ConfigLoad(nil, nil, to_cs(string(s)))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
	config, ok := resp.Result.(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if config["test_key"] != "test_val" {
		t.Errorf("%s != test_val", config["test_key"])
	}
	if config["sent_key"] != "custom_val" {
		t.Errorf("%s != custom_val", config["sent_key"])
	}
}

func TestConfig_Attributes(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"config": &vplugin.ConfigPlugin{Impl: &vplugin.MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("config")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteConfig{
		Config: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ConfigAttributes(nil, nil)
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
	attrs, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if len(attrs) != 2 {
		t.Fatalf("%d != 2", len(attrs))
	}
	if attrs[0] != "fubar" {
		t.Errorf("%s != fubar", attrs[0])
	}
	if attrs[1] != "foobar" {
		t.Errorf("%s != foobar", attrs[1])
	}
}

func TestConfig_Validate(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"config": &vplugin.ConfigPlugin{Impl: &vplugin.MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("config")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteConfig{
		Config: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	data := map[string]string{"test_key": "custom_val"}
	s, err := json.Marshal(data)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	result := ConfigValidate(nil, nil, to_cs(string(s)), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
	errs, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if len(errs) != 1 {
		t.Fatalf("%d != 1", len(errs))
	}
	if errs[0] != "test error" {
		t.Errorf("%s != test error", errs[0])
	}
}

func TestConfig_Finalize(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"config": &vplugin.ConfigPlugin{Impl: &vplugin.MockConfig{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("config")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Config)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteConfig{
		Config: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	data := map[string]string{"test_key": "custom_val"}
	s, err := json.Marshal(data)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	result := ConfigFinalize(nil, nil, to_cs(string(s)))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
	config, ok := resp.Result.(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if config["test_key"] != "custom_val-updated" {
		t.Errorf("%s != custom_val-updated", config["test_key"])
	}
}
