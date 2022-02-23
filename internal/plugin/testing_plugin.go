package plugin

import (
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/mitchellh/go-testing-interface"
)

func TestMinimalPlugin(t testing.T) *Plugin {
	plugin := &Plugin{
		Location: "test",
		logger:   hclog.New(&hclog.LoggerOptions{}),
	}
	return plugin
}

// TestPlugin returns a fully in-memory and side-effect free Plugin that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestPlugin(t testing.T, opts ...PluginProperty) (plugin *Plugin) {
	plugin = TestMinimalPlugin(t)
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

func WithPluginComponents(t component.Type, i interface{}) PluginProperty {
	return func(p *Plugin) (err error) {
		instance := &Instance{
			Name:      p.Name,
			Type:      t,
			Component: i,
		}
		p.components = make(map[component.Type]*Instance)
		p.components[t] = instance
		p.Types = append(p.Types, t)
		return
	}
}
