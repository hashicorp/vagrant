package plugin

import (
	"github.com/hashicorp/go-hclog"
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
