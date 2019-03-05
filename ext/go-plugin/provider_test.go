package main

import (
	"encoding/json"
	"testing"

	"github.com/hashicorp/go-plugin"
	vplugin "github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

func TestProvider_ListProviders(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.Providers[impl.Name()] = p

	result := ListProviders()
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if r["mock_provider"] == nil {
		t.Fatalf("bad result")
	}

	i, ok := r["mock_provider"].(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", r["mock_provider"])
	}

	if i["description"] != "Custom" {
		t.Errorf("%s != Custom", i["description"])
	}
	if i["priority"] != 10.0 {
		t.Errorf("%d != 10", i["priority"])
	}
}

func TestProvider_ProviderAction(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ProviderAction(nil, to_cs("valid"), to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
	r := resp.Result.([]interface{})
	if r[0] != "self::DoTask" {
		t.Errorf("%s != self::DoTask", r[0])
	}
}

func TestProvider_ProviderIsInstalled(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ProviderIsInstalled(nil, to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}

	if !resp.Result.(bool) {
		t.Errorf("bad result")
	}
}

func TestProvider_ProviderIsUsable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ProviderIsUsable(nil, to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}

	if !resp.Result.(bool) {
		t.Errorf("bad result")
	}
}

func TestProvider_ProviderMachineIdChanged(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ProviderMachineIdChanged(nil, to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
}

func TestProvider_ProviderRunAction(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	a, err := json.Marshal([]string{"test_arg"})
	args := string(a)

	result := ProviderRunAction(nil, to_cs("valid"), to_cs(args), to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}
	if r[0] != "valid" {
		t.Errorf("%s != valid", r[0])
	}
	if r[1] != "test_arg" {
		t.Errorf("%s != test_arg", r[1])
	}
}

func TestProvider_ProviderSshInfo(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ProviderSshInfo(nil, to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if r["host"] != "localhost" {
		t.Errorf("%s != localhost", r["host"])
	}
	if r["port"] != 2222.0 {
		t.Errorf("%d != 2222", r["port"])
	}
}

func TestProvider_ProviderState(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &vplugin.ProviderPlugin{Impl: &vplugin.MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteProvider{
		Provider: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = p
		return
	}

	result := ProviderState(nil, to_cs("{}"))
	resp, err := LoadResponse(result)
	if resp.Error != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if r["id"] != "default" {
		t.Errorf("%s != default", r["id"])
	}
	if r["short_description"] != "running" {
		t.Errorf("%s != running", r["short_description"])
	}
}
