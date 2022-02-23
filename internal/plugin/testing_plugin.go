package plugin

import (
	"github.com/mitchellh/go-testing-interface"
)

// TestPlugin returns a fully in-memory and side-effect free Plugin that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestPlugin(t testing.T) *Plugin {
	plugin := &Plugin{}
	return plugin
}
