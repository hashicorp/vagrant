package plugin

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

func TestProvider_Action(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp, err := impl.Action(context.Background(), "valid", &vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if resp[0] != "self::DoTask" {
		t.Errorf("%s != self::DoTask", resp[0])
	}
}

func TestProvider_Action_invalid(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	_, err = impl.Action(context.Background(), "invalid", &vagrant.Machine{})
	if err == nil {
		t.Errorf("illegal action")
	}
}

func TestProvider_Action_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	_, err = impl.Action(ctx, "pause", &vagrant.Machine{})
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_Action_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	_, err = impl.Action(ctx, "pause", &vagrant.Machine{})
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_IsInstalled(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	installed, err := impl.IsInstalled(context.Background(), &vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !installed {
		t.Errorf("bad result")
	}
}

func TestProvider_IsInstalled_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	_, err = impl.IsInstalled(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_IsInstalled_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	_, err = impl.IsInstalled(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
	}
}
func TestProvider_IsUsable(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}
	usable, err := impl.IsUsable(context.Background(), &vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !usable {
		t.Errorf("bad result")
	}
}

func TestProvider_IsUsable_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
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

func TestProvider_IsUsable_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
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
func TestProvider_MachineIdChanged(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	err = impl.MachineIdChanged(context.Background(), &vagrant.Machine{})
	if err != nil {
		t.Errorf("err: %s", err)
	}
}

func TestProvider_MachineIdChanged_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	err = impl.MachineIdChanged(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_MachineIdChanged_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	err = impl.MachineIdChanged(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_Name(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp := impl.Name()
	if resp != "mock_provider" {
		t.Errorf("%s != mock_provider", resp)
	}
}

func TestProvider_RunAction(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	args := []string{"test_arg", "other_arg"}
	m := &vagrant.Machine{}

	resp, err := impl.RunAction(context.Background(), "valid", args, m)
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}

	result := resp.([]interface{})
	if result[0] != "valid" {
		t.Errorf("%s != valid", result[0])
	}
	if result[1] != "test_arg" {
		t.Errorf("%s != test_arg", result[1])
	}
}

func TestProvider_RunAction_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	args := []string{"test_arg", "other_arg"}
	m := &vagrant.Machine{}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	_, err = impl.RunAction(ctx, "pause", args, m)
	if err != context.Canceled {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_RunAction_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	args := []string{"test_arg", "other_arg"}
	m := &vagrant.Machine{}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	_, err = impl.RunAction(ctx, "pause", args, m)
	if err != context.DeadlineExceeded {
		t.Fatalf("bad resp: %s", err)
	}
}

func TestProvider_RunAction_invalid(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	args := []string{"test_arg", "other_arg"}
	m := &vagrant.Machine{}

	_, err = impl.RunAction(context.Background(), "invalid", args, m)
	if err == nil {
		t.Fatalf("illegal action run")
	}
}

func TestProvider_SshInfo(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp, err := impl.SshInfo(context.Background(), &vagrant.Machine{})
	if err != nil {
		t.Fatalf("invalid resp: %s", err)
	}

	if resp.Host != "localhost" {
		t.Errorf("%s != localhost", resp.Host)
	}
	if resp.Port != 2222 {
		t.Errorf("%d != 2222", resp.Port)
	}
}

func TestProvider_SshInfo_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	_, err = impl.SshInfo(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.Canceled {
		t.Fatalf("invalid resp: %s", err)
	}
}

func TestProvider_SshInfo_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	_, err = impl.SshInfo(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.DeadlineExceeded {
		t.Fatalf("invalid resp: %s", err)
	}
}

func TestProvider_State(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp, err := impl.State(context.Background(), &vagrant.Machine{})
	if err != nil {
		t.Fatalf("invalid resp: %s", err)
	}

	if resp.Id != "default" {
		t.Errorf("%s != default", resp.Id)
	}
	if resp.ShortDesc != "running" {
		t.Errorf("%s != running", resp.ShortDesc)
	}
}

func TestProvider_State_context_cancel(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	go func() {
		time.Sleep(2 * time.Millisecond)
		cancel()
	}()
	_, err = impl.State(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.Canceled {
		t.Fatalf("invalid resp: %s", err)
	}
}

func TestProvider_State_context_timeout(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Millisecond)
	defer cancel()
	_, err = impl.State(ctx, &vagrant.Machine{Name: "pause"})
	if err != context.DeadlineExceeded {
		t.Fatalf("invalid resp: %s", err)
	}
}

func TestProvider_Info(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	resp := impl.Info()

	if resp.Description != "Custom" {
		t.Errorf("%s != Custom", resp.Description)
	}
	if resp.Priority != 10 {
		t.Errorf("%d != 10", resp.Priority)
	}
}

func TestProvider_MachineUI_output(t *testing.T) {
	client, server := plugin.TestPluginGRPCConn(t, map[string]plugin.Plugin{
		"provider": &ProviderPlugin{Impl: &MockProvider{}}})
	defer server.Stop()
	defer client.Close()

	raw, err := client.Dispense("provider")
	if err != nil {
		t.Fatalf("err: %s", err)
	}
	impl, ok := raw.(Provider)
	if !ok {
		t.Fatalf("bad %#v", raw)
	}

	ctx := context.Background()
	go func() {
		_, err = impl.RunAction(ctx, "send_output", nil, &vagrant.Machine{})
		if err != nil {
			t.Fatalf("bad resp: %s", err)
		}
	}()

	resp, err := impl.Read("stdout")
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}

	if !strings.Contains(resp, "test_output_p") {
		t.Errorf("%s !~ test_output_p", resp)
	}
}
