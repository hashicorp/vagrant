// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package plugin

import (
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/mitchellh/go-testing-interface"
)

type TestPluginWithFakeBroker struct {
}

func (p *TestPluginWithFakeBroker) GRPCBroker() *plugin.GRPCBroker {
	return &plugin.GRPCBroker{}
}

type MockClientProtocol struct {
	plg interface{}
}

func (m *MockClientProtocol) Dispense(s string) (interface{}, error) {
	return m.plg, nil
}

func (m *MockClientProtocol) Ping() error {
	return nil
}

func (m *MockClientProtocol) Close() error {
	return nil
}

func TestMinimalPlugin(t testing.T, client interface{}) *Plugin {
	plugin := &Plugin{
		Location: "test",
		Client:   client.(plugin.ClientProtocol),
		logger:   hclog.New(&hclog.LoggerOptions{}),
		cleaner:  cleanup.New(),
	}
	return plugin
}

// TestPlugin returns a fully in-memory and side-effect free Plugin that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestPlugin(t testing.T, plg interface{}, opts ...PluginProperty) (plugin *Plugin) {
	mockClient := &MockClientProtocol{
		plg: plg,
	}
	plugin = TestMinimalPlugin(t, mockClient)
	for _, opt := range opts {
		if err := opt(plugin); err != nil {
			t.Error(err)
		}
	}
	return
}

type PluginProperty func(*Plugin) error

func WithPluginName(name string) PluginProperty {
	return func(p *Plugin) (err error) {
		p.Name = name
		return
	}
}

func WithPluginTypes(types ...component.Type) PluginProperty {
	return func(p *Plugin) (err error) {
		p.Types = types
		return
	}
}
