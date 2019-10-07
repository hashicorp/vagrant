package plugin

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

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

	err = impl.Cleanup(context.Background(), &vagrant.Machine{}, nil)
	if err != nil {
		t.Fatalf("bad resp: %#v", err)
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

	err = impl.Cleanup(context.Background(), &vagrant.Machine{}, args)
	if err == nil {
		t.Fatalf("illegal cleanup")
	}
	if err.Error() != "cleanup error" {
		t.Errorf("%s != cleanup error", err.Error())
	}
}

func TestSyncedFolder_Cleanup_context_cancel(t *testing.T) {
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

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	err = impl.Cleanup(ctx, &vagrant.Machine{Name: "pause"}, nil)
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Cleanup_context_timeout(t *testing.T) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	err = impl.Cleanup(ctx, &vagrant.Machine{Name: "pause"}, nil)
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
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

	err = impl.Disable(context.Background(), &vagrant.Machine{}, nil, nil)
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

	err = impl.Disable(context.Background(), &vagrant.Machine{}, folders, args)
	if err == nil {
		t.Fatalf("illegal disable")
	}
	if err.Error() != "disable error" {
		t.Errorf("%s != disable error", err.Error())
	}
}

func TestSyncedFolder_Disable_context_cancel(t *testing.T) {
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

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	err = impl.Disable(ctx, &vagrant.Machine{Name: "pause"}, nil, nil)
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Disable_context_timeout(t *testing.T) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	err = impl.Disable(ctx, &vagrant.Machine{Name: "pause"}, nil, nil)
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
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

	err = impl.Enable(context.Background(), &vagrant.Machine{}, nil, nil)
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

	err = impl.Enable(context.Background(), &vagrant.Machine{}, folders, args)
	if err == nil {
		t.Fatalf("illegal enable")
	}
	if err.Error() != "enable error" {
		t.Errorf("%s != enable error", err.Error())
	}
}

func TestSyncedFolder_Enable_context_cancel(t *testing.T) {
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

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	err = impl.Enable(ctx, &vagrant.Machine{Name: "pause"}, nil, nil)
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Enable_context_timeout(t *testing.T) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	err = impl.Enable(ctx, &vagrant.Machine{Name: "pause"}, nil, nil)
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
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

	err = impl.Prepare(context.Background(), &vagrant.Machine{}, nil, nil)
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

	err = impl.Prepare(context.Background(), &vagrant.Machine{}, folders, args)
	if err == nil {
		t.Fatalf("illegal prepare")
	}
	if err.Error() != "prepare error" {
		t.Errorf("%s != prepare error", err.Error())
	}
}

func TestSyncedFolder_Prepare_context_cancel(t *testing.T) {
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

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	err = impl.Prepare(ctx, &vagrant.Machine{Name: "pause"}, nil, nil)
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_Prepare_context_timeout(t *testing.T) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	err = impl.Prepare(ctx, &vagrant.Machine{Name: "pause"}, nil, nil)
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
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

	resp, err := impl.IsUsable(context.Background(), &vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !resp {
		t.Errorf("bad result")
	}
}

func TestSyncedFolder_IsUsable_context_cancel(t *testing.T) {
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

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	_, err = impl.IsUsable(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestSyncedFolder_IsUsable_context_timeout(t *testing.T) {
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

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	_, err = impl.IsUsable(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
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
		err := impl.Cleanup(context.Background(), &vagrant.Machine{}, map[string]interface{}{"ui": true})
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
