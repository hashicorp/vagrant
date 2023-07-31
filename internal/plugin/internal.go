// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package plugin

import (
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
)

// Returns value that implements Internal interface
// used by mappers. This allows us to generate clients
// for the managers in a common way.
func NewInternal(
	broker *plugin.GRPCBroker,
	cache cacher.Cache,
	cleanup cleanup.Cleanup,
	logger hclog.Logger,
	mappers []*argmapper.Func,
) *internal {
	return &internal{
		broker:  broker,
		cache:   cache,
		cleanup: cleanup,
		logger:  logger,
		mappers: mappers,
	}
}

func Internal(l hclog.Logger, m []*argmapper.Func) *internal {
	return &internal{
		broker:  nil,
		cache:   cacher.New(),
		cleanup: cleanup.New(),
		logger:  l,
		mappers: m,
	}
}

type internal struct {
	broker  *plugin.GRPCBroker
	cache   cacher.Cache
	cleanup cleanup.Cleanup
	logger  hclog.Logger
	mappers []*argmapper.Func
}

// Broker implements Internal
func (i *internal) Broker() *plugin.GRPCBroker {
	return i.broker
}

// Cache implements Internal
func (i *internal) Cache() cacher.Cache {
	return i.cache
}

// Cleanup implements Internal
func (i *internal) Cleanup() cleanup.Cleanup {
	return i.cleanup
}

// Logger implements Internal
func (i *internal) Logger() hclog.Logger {
	return i.logger
}

// Mappers implements Internal
func (i *internal) Mappers() []*argmapper.Func {
	return i.mappers
}
