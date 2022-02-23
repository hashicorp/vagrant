package plugin

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/mitchellh/go-testing-interface"
)

// TestManager returns a fully in-memory and side-effect free Manager that
// can be used for testing.
func TestManager(t testing.T, plugins ...*Plugin) *Manager {
	pluginManager := NewManager(
		context.Background(),
		hclog.New(&hclog.LoggerOptions{}),
	)
	pluginManager.Plugins = plugins
	return pluginManager
}
