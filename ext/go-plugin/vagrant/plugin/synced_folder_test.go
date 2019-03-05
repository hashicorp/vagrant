package plugin

import (
	"errors"
	"strings"
	"testing"

	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

type MockSyncedFolder struct {
	Core
	vagrant.NoGuestCapabilities
	vagrant.NoHostCapabilities
}

func (s *MockSyncedFolder) Cleanup(m *vagrant.Machine, opts vagrant.FolderOptions) error {
	if opts != nil {
		err, _ := opts["error"].(bool)
		ui, _ := opts["ui"].(bool)
		if err {
			return errors.New("cleanup error")
		}
		if ui {
			m.UI.Say("test_output_sf")
			return nil
		}
	}
	return nil
}

func (s *MockSyncedFolder) Disable(m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if opts != nil && opts["error"].(bool) {
		return errors.New("disable error")
	}
	return nil
}

func (s *MockSyncedFolder) Enable(m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if opts != nil && opts["error"].(bool) {
		return errors.New("enable error")
	}
	return nil
}

func (s *MockSyncedFolder) Info() *vagrant.SyncedFolderInfo {
	return &vagrant.SyncedFolderInfo{
		Description: "mock_folder",
		Priority:    100}
}

func (s *MockSyncedFolder) IsUsable(m *vagrant.Machine) (bool, error) {
	return true, nil
}

func (s *MockSyncedFolder) Name() string {
	return "mock_folder"
}

func (s *MockSyncedFolder) Prepare(m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if opts != nil && opts["error"].(bool) {
		return errors.New("prepare error")
	}
	return nil
}

func TestSyncedFolder_Cleanup(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	err = impl.Cleanup(&vagrant.Machine{}, nil)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Cleanup_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	args := map[string]interface{}{
		"error": true}

	err = impl.Cleanup(&vagrant.Machine{}, args)
	if err == nil {
		t.Fatalf("illegal cleanup")
	}
	if err.Error() != "cleanup error" {
		t.Errorf("%s != cleanup error", err.Error())
	}
}

func TestSyncedFolder_Disable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	err = impl.Disable(&vagrant.Machine{}, nil, nil)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Disable_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	folders := map[string]interface{}{
		"folder_name": "options"}
	args := map[string]interface{}{
		"error": true}

	err = impl.Disable(&vagrant.Machine{}, folders, args)
	if err == nil {
		t.Fatalf("illegal disable")
	}
	if err.Error() != "disable error" {
		t.Errorf("%s != disable error", err.Error())
	}
}

func TestSyncedFolder_Enable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	err = impl.Enable(&vagrant.Machine{}, nil, nil)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Enable_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	folders := map[string]interface{}{
		"folder_name": "options"}
	args := map[string]interface{}{
		"error": true}

	err = impl.Enable(&vagrant.Machine{}, folders, args)
	if err == nil {
		t.Fatalf("illegal enable")
	}
	if err.Error() != "enable error" {
		t.Errorf("%s != enable error", err.Error())
	}
}

func TestSyncedFolder_Prepare(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	err = impl.Prepare(&vagrant.Machine{}, nil, nil)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Prepare_error(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	folders := map[string]interface{}{
		"folder_name": "options"}
	args := map[string]interface{}{
		"error": true}

	err = impl.Prepare(&vagrant.Machine{}, folders, args)
	if err == nil {
		t.Fatalf("illegal prepare")
	}
	if err.Error() != "prepare error" {
		t.Errorf("%s != prepare error", err.Error())
	}
}

func TestSyncedFolder_Info(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp := impl.Info()
	if resp == nil {
		t.Fatalf("bad resp")
	}

	if resp.Description != "mock_folder" {
		t.Errorf("%s != mock_folder", resp.Description)
	}
	if resp.Priority != 100 {
		t.Errorf("%d != 100", resp.Priority)
	}
}

func TestSyncedFolder_IsUsable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp, err := impl.IsUsable(&vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !resp {
		t.Errorf("bad result")
	}
}

func TestSyncedFolder_Name(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp := impl.Name()
	if resp != "mock_folder" {
		t.Errorf("%s != mock_folder", resp)
	}
}

func TestSyncedFolder_MachineUI_output(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"folder": &SyncedFolderPlugin{Impl: &MockSyncedFolder{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("folder")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(SyncedFolder)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	go func() {
		err := impl.Cleanup(&vagrant.Machine{}, map[string]interface{}{"ui": true})
		if err != nil {
			t.Fatalf("bad resp: %s", err)
		}
	}()

	resp, err := impl.Read("stdout")
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !strings.Contains(resp, "test_output") {
		t.Errorf("%s !~ test_output", resp)
	}
}
