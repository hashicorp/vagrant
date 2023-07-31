// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"github.com/hashicorp/go-argmapper"

	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Component struct {
	Value interface{}
	Info  *vagrant_server.Component

	// Options for component type, see PluginInfo.ComponentOptions
	Options interface{}

	// These fields can be accessed internally
	hooks   map[string][]*config.Hook
	labels  map[string]string
	mappers []*argmapper.Func

	// These are private, please do not access them ever except as an
	// internal Component implementation detail.
	closed bool
	plugin *plugin.Instance
}

// Close cleans up any resources associated with the Component. Close should
// always be called when the component is done being used.
func (c *Component) Close() error {
	if c == nil {
		return nil
	}

	// If we closed already do nothing.
	if c.closed {
		return nil
	}

	c.closed = true
	if c.plugin != nil {
		c.plugin.Close()
	}

	return nil
}
