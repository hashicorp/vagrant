package main

import (
	"encoding/json"
	"testing"

	"github.com/hashicorp/go-plugin"
	vplugin "github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

func TestCapabilities_GuestCapabilities(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.GuestCapabilitiesPlugin{Impl: &vplugin.MockGuestCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.GuestCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := GuestCapabilities(nil, nil)
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	caps, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	cap, ok := caps[0].(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", caps[0])
	}

	if cap["name"] != "test_cap" {
		t.Errorf("%s != test_cap", cap["name"])
	}
	if cap["platform"] != "testOS" {
		t.Errorf("%s != testOS", cap["platform"])
	}
}

func TestCapabilities_GuestCapability(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.GuestCapabilitiesPlugin{Impl: &vplugin.MockGuestCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.GuestCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	a, err := json.Marshal([]string{"test_arg", "other_arg"})
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	args := string(a)
	result := GuestCapability(nil, nil, to_cs("test_cap"), to_cs("test_platform"), to_cs(args), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if r[0] != "test_cap" {
		t.Errorf("%s != test_cap", r[0])
	}
	if r[1] != "test_arg" {
		t.Errorf("%s != test_arg", r[1])
	}
}

func TestCapabilities_GuestCapability_noargs(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.GuestCapabilitiesPlugin{Impl: &vplugin.MockGuestCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.GuestCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := GuestCapability(nil, nil, to_cs("test_cap"), to_cs("test_platform"), to_cs("null"), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s - %s", err, to_gs(result))
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if len(r) != 1 {
		t.Errorf("%d != 1", len(r))
	}
	if r[0] != "test_cap" {
		t.Errorf("%s != test_cap", r[0])
	}
}

func TestCapabilities_HostCapabilities(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.HostCapabilitiesPlugin{Impl: &vplugin.MockHostCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.HostCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := HostCapabilities(nil, nil)
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	caps, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	cap, ok := caps[0].(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", caps[0])
	}

	if cap["name"] != "test_cap" {
		t.Errorf("%s != test_cap", cap["name"])
	}
	if cap["platform"] != "testOS" {
		t.Errorf("%s != testOS", cap["platform"])
	}
}

func TestCapabilities_HostCapability(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.HostCapabilitiesPlugin{Impl: &vplugin.MockHostCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.HostCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	a, err := json.Marshal([]string{"test_arg", "other_arg"})
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	args := string(a)
	result := HostCapability(nil, nil, to_cs("test_cap"), to_cs("test_platform"), to_cs(args), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if r[0] != "test_cap" {
		t.Errorf("%s != test_cap", r[0])
	}
	if r[1] != "test_arg" {
		t.Errorf("%s != test_arg", r[1])
	}
}

func TestCapabilities_HostCapability_noargs(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.HostCapabilitiesPlugin{Impl: &vplugin.MockHostCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.HostCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := HostCapability(nil, nil, to_cs("test_cap"), to_cs("test_platform"), to_cs("null"), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s - %s", err, to_gs(result))
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if len(r) != 1 {
		t.Errorf("%d != 1", len(r))
	}
	if r[0] != "test_cap" {
		t.Errorf("%s != test_cap", r[0])
	}
}

func TestCapabilities_ProviderCapabilities(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.ProviderCapabilitiesPlugin{Impl: &vplugin.MockProviderCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.ProviderCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := ProviderCapabilities(nil, nil)
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	caps, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	cap, ok := caps[0].(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", caps[0])
	}

	if cap["name"] != "test_cap" {
		t.Errorf("%s != test_cap", cap["name"])
	}
	if cap["provider"] != "testProvider" {
		t.Errorf("%s != testProvider", cap["provider"])
	}
}

func TestCapabilities_ProviderCapability(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.ProviderCapabilitiesPlugin{Impl: &vplugin.MockProviderCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.ProviderCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	a, err := json.Marshal([]string{"test_arg", "other_arg"})
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	args := string(a)
	result := ProviderCapability(nil, nil, to_cs("test_cap"), to_cs("test_provider"), to_cs(args), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if r[0] != "test_cap" {
		t.Errorf("%s != test_cap", r[0])
	}
	if r[1] != "test_arg" {
		t.Errorf("%s != test_arg", r[1])
	}
}

func TestCapabilities_ProviderCapability_noargs(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"caps": &vplugin.ProviderCapabilitiesPlugin{Impl: &vplugin.MockProviderCapabilities{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("caps")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.ProviderCapabilities)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := ProviderCapability(nil, nil, to_cs("test_cap"), to_cs("test_provider"), to_cs("null"), to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s - %s", err, to_gs(result))
	}

	r, ok := resp.Result.([]interface{})
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if len(r) != 1 {
		t.Errorf("%d != 1", len(r))
	}
	if r[0] != "test_cap" {
		t.Errorf("%s != test_cap", r[0])
	}
}
