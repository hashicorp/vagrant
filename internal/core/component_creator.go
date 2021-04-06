package core

import (
	"context"
	//	"fmt"

	"github.com/hashicorp/go-argmapper"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Component struct {
	Value interface{}
	Info  *vagrant_server.Component

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

// componentCreator represents the configuration to initialize the component
// for a given application.
type componentCreator struct {
	Type component.Type
}

// componentCreatorMap contains all the components that can be initialized
// for an app.
var componentCreatorMap = map[component.Type]*componentCreator{
	component.CommandType: {
		Type: component.CommandType,
	},
	component.ProviderType: {
		Type: component.ProviderType,
	},
	component.HostType: {
		Type: component.HostType,
	},
}

// Create creates the component of the given type.
func (cc *componentCreator) Create(
	ctx context.Context,
	scope interface{},
	pluginName string,
) (*Component, error) {
	s, ok := scope.(interface {
		startPlugin(context.Context, component.Type, string) (*plugin.Instance, error)
	})
	if !ok {
		panic("the scope provided is invalid")
	}

	// Start the plugin
	pinst, err := s.startPlugin(
		ctx,
		cc.Type,
		pluginName,
	)
	if err != nil {
		return nil, err
	}

	// TODO: configure
	// If we have a config, configure
	// Configure the component. This will handle all the cases where no
	// config is given but required, vice versa, and everything in between.
	// diag := component.Configure(pinst.Component, opCfg.Use.Body, hclCtx)
	// if diag.HasErrors() {
	// 	pinst.Close()
	// 	return nil, diag
	// }

	// TODO: Setup hooks
	hooks := map[string][]*config.Hook{}
	// for _, h := range opCfg.Hooks {
	// 	hooks[h.When] = append(hooks[h.When], h)
	// }

	return &Component{
		Value: pinst.Component,
		Info: &vagrant_server.Component{
			Type: vagrant_server.Component_Type(cc.Type),
			Name: pluginName,
		},

		hooks:   hooks,
		mappers: pinst.Mappers,
		plugin:  pinst,
	}, nil
}

type pluginer interface {
	startPlugin(context.Context, component.Type, string) (*plugin.Instance, error)
}
