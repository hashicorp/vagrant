// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"context"
	"io"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	intplugin "github.com/hashicorp/vagrant/internal/plugin"
	"google.golang.org/protobuf/encoding/protojson"
)

type CoreManager struct {
	cleanup cleanup.Cleanup
	ctx     context.Context
	logger  hclog.Logger // Logger for the manager
	m       sync.Mutex
	srv     []byte // Marshalled proto message for plugin manager
}

func NewCoreManager(ctx context.Context, l hclog.Logger) *CoreManager {
	var logger hclog.Logger
	if l.IsTrace() {
		logger = l.Named("coremanager")
	} else {
		logger = l.ResetNamed("coremanager")
	}

	return &CoreManager{
		cleanup: cleanup.New(),
		ctx:     ctx,
		logger:  logger,
	}
}

func (m *CoreManager) generatePlugin(fn func() (plg interface{})) (plg interface{}, err error) {
	plg = fn()
	if p, ok := plg.(io.Closer); ok {
		m.cleanup.Do(func() error {
			return p.Close()
		})
	}
	return plg, nil
}

// Get a fresh instance of a core plugin
func (m *CoreManager) GetPlugin(pluginType sdkcore.Type) (plg interface{}, err error) {
	switch pluginType {
	case sdkcore.BoxCollectionType:
		return m.generatePlugin(func() (plg interface{}) {
			return &BoxCollection{}
		})
	case sdkcore.BoxMetadataType:
		return m.generatePlugin(func() (plg interface{}) {
			return &BoxMetadata{}
		})
	case sdkcore.BoxType:
		return m.generatePlugin(func() (plg interface{}) {
			return &Box{}
		})
	case sdkcore.StateBagType:
		return m.generatePlugin(func() (plg interface{}) {
			return NewStateBag()
		})
	}
	return
}

func (m *CoreManager) Servinfo(broker *plugin.GRPCBroker) ([]byte, error) {
	if m.srv != nil {
		return m.srv, nil
	}

	i := intplugin.NewInternal(
		broker,
		cacher.New(),
		m.cleanup,
		m.logger,
		[]*argmapper.Func{},
	)

	p, err := protomappers.CorePluginManagerProto(m, m.logger, i)
	if err != nil {
		m.logger.Warn("failed to create plugin manager grpc server",
			"error", err,
		)

		return nil, err
	}

	m.logger.Info("new GRPC server instance started",
		"address", p.Addr,
	)

	m.srv, err = protojson.Marshal(p)

	return m.srv, err
}

// Close the manager (and all managed plugins)
func (m *CoreManager) Close() error {
	m.m.Lock()
	defer m.m.Unlock()

	m.logger.Warn("closing the core plugin manager")
	return m.cleanup.Close()
}

var _ sdkcore.CorePluginManager = (*CoreManager)(nil)
