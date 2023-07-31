// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package plugin

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/mitchellh/go-testing-interface"
)

func TestMinimalPluginInstance(t testing.T) *Instance {
	inst := &Instance{
		Name: "test",
	}
	return inst
}

func TestPluginInstance(t testing.T, opts ...PluginInstanceProperty) *Instance {
	inst := TestMinimalPluginInstance(t)
	for _, opt := range opts {
		if err := opt(inst); err != nil {
			t.Error(err)
		}
	}
	return inst
}

type PluginInstanceProperty func(*Instance) error

func WithPluginInstanceName(name string) PluginInstanceProperty {
	return func(i *Instance) (err error) {
		i.Name = name
		return
	}
}

func WithPluginInstanceType(t component.Type) PluginInstanceProperty {
	return func(i *Instance) (err error) {
		i.Type = t
		return
	}
}

func WithPluginInstanceComponent(c interface{}) PluginInstanceProperty {
	return func(i *Instance) (err error) {
		i.Component = c
		return
	}
}

func WithPluginInstanceParent(p *Instance) PluginInstanceProperty {
	return func(i *Instance) (err error) {
		i.Parent = p
		return
	}
}
