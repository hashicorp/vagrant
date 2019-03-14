package main

import (
	"testing"

	"github.com/hashicorp/go-plugin"
	vplugin "github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

func TestSyncedFolder_ListSyncedFolders(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	p := &vplugin.RemoteSyncedFolder{
		SyncedFolder: impl}
	Plugins = vplugin.VagrantPluginInit()
	Plugins.SyncedFolders[impl.Name()] = p

	result := ListSyncedFolders()
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

	if r["mock_folder"] == nil {
		t.Fatalf("bad result")
	}

	i, ok := r["mock_folder"].(map[string]interface{})
	if !ok {
		t.Fatalf("bad %#v", r["mock_folder"])
	}

	if i["description"] != "mock_folder" {
		t.Errorf("%s != mock_folder", i["description"])
	}
	if i["priority"] != 100.0 {
		t.Errorf("%d != 100", i["priority"])
	}
}

func TestSyncedFolder_SyncedFolderCleanup(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderCleanup(nil, to_cs("{}"), to_cs("null"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
}

func TestSyncedFolder_SyncedFolderCleanup_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderCleanup(nil, to_cs("{}"), to_cs("{\"error\":true}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error == nil {
		t.Fatalf("error expected")
	}
}

func TestSyncedFolder_SyncedFolderDisable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderDisable(nil, to_cs("{}"), to_cs("{}"), to_cs("null"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
}

func TestSyncedFolder_SyncedFolderDisable_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderDisable(nil, to_cs("{}"), to_cs("{}"), to_cs("{\"error\":true}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error == nil {
		t.Fatalf("rror expected")
	}
}

func TestSyncedFolder_SyncedFolderEnable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderEnable(nil, to_cs("{}"), to_cs("{}"), to_cs("null"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
}

func TestSyncedFolder_SyncedFolderEnable_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderEnable(nil, to_cs("{}"), to_cs("{}"), to_cs("{\"error\":true}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error == nil {
		t.Fatalf("rror expected")
	}
}

func TestSyncedFolder_SyncedFolderIsUsable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderIsUsable(nil, to_cs("{}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}

	usable, ok := resp.Result.(bool)
	if !ok {
		t.Fatalf("bad %#v", resp.Result)
	}

	if !usable {
		t.Fatalf("bad result")
	}
}

func TestSyncedFolder_SyncedFolderPrepare(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderPrepare(nil, to_cs("{}"), to_cs("{}"), to_cs("null"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error != nil {
		t.Fatalf("err: %s", resp.Error)
	}
}

func TestSyncedFolder_SyncedFolderPrepare_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &vplugin.SyncedFolderPlugin{Impl: &vplugin.MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(vplugin.SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	Plugins = vplugin.VagrantPluginInit()
	Plugins.PluginLookup = func(_, _ string) (r interface{}, err error) {
		r = impl
		return
	}

	result := SyncedFolderPrepare(nil, to_cs("{}"), to_cs("{}"), to_cs("{\"error\":true}"))
	resp, err := LoadResponse(result)
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	if resp.Error == nil {
		t.Fatalf("error expected")
	}
}
