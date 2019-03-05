package plugin

import (
	"strings"
	"testing"

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

	resp, err := impl.Action("valid", &vagrant.Machine{})
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

	_, err = impl.Action("invalid", &vagrant.Machine{})
	if err == nil {
		t.Errorf("illegal action")
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

	installed, err := impl.IsInstalled(&vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !installed {
		t.Errorf("bad result")
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

	usable, err := impl.IsUsable(&vagrant.Machine{})
	if err != nil {
		t.Fatalf("bad resp: %s", err)
	}
	if !usable {
		t.Errorf("bad result")
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

	err = impl.MachineIdChanged(&vagrant.Machine{})
	if err != nil {
		t.Errorf("err: %s", err)
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

	resp, err := impl.RunAction("valid", args, m)
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

	_, err = impl.RunAction("invalid", args, m)
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

	resp, err := impl.SshInfo(&vagrant.Machine{})
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

	resp, err := impl.State(&vagrant.Machine{})
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

	go func() {
		_, err = impl.RunAction("send_output", nil, &vagrant.Machine{})
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
