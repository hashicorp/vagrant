// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

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
		nil,
		hclog.New(&hclog.LoggerOptions{}),
	)
	pluginManager.Plugins = plugins
	return pluginManager
}
