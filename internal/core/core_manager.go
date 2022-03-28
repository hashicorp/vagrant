package core

import (
	"context"
	"sync"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	plg "github.com/hashicorp/go-plugin"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant/internal/plugin"
	"google.golang.org/protobuf/encoding/protojson"
)

type CoreManager struct {
	closers []func() error // List of functions to execute on close
	ctx     context.Context
	logger  hclog.Logger // Logger for the manager
	m       sync.Mutex
	srv     []byte // Marshalled proto message for plugin manager
}

func (m *CoreManager) closer(f func() error) {
	m.closers = append(m.closers, f)
}

// Interface for plugins which allow broker access
type Closer interface {
	Close() error
}

func (m *CoreManager) generatePlugin(fn func() (plg interface{})) (plg interface{}, err error) {
	plg = fn()
	if p, ok := plg.(Closer); ok {
		m.closer(func() error {
			return p.Close()
		})
	}
	return plg, nil
}

// Get a fresh instance of a core plugin
func (m *CoreManager) GetPlugin(pluginType sdkcore.Type) (plg interface{}, err error) {
	switch pluginType {
	case sdkcore.BasisType:
		return m.generatePlugin(func() (plg interface{}) {
			return &Basis{}
		})
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
	case sdkcore.MachineType:
		return m.generatePlugin(func() (plg interface{}) {
			return &Machine{}
		})
	case sdkcore.PluginManagerType:
		return m.generatePlugin(func() (plg interface{}) {
			return plugin.NewManager(m.ctx, m.logger.Named("plugin-manager"))
		})
	case sdkcore.ProjectType:
		return m.generatePlugin(func() (plg interface{}) {
			return &Project{}
		})
	case sdkcore.StateBagType:
		return m.generatePlugin(func() (plg interface{}) {
			return NewStateBag()
		})
	case sdkcore.TargetIndexType:
		return m.generatePlugin(func() (plg interface{}) {
			return &TargetIndex{}
		})
	case sdkcore.TargetType:
		return m.generatePlugin(func() (plg interface{}) {
			return &Target{}
		})
	}
	return
}

func (m *CoreManager) Servinfo(broker *plg.GRPCBroker) ([]byte, error) {
	if m.srv != nil {
		return m.srv, nil
	}

	p, closer, err := protomappers.CorePluginManagerProtoDirect(m, m.logger, broker)
	if err != nil {
		m.logger.Warn("failed to create plugin manager grpc server",
			"error", err,
		)

		return nil, err
	}

	fn := func() error {
		m.logger.Info("closing the GRPC server instance")
		closer()
		m.srv = nil
		return nil
	}
	m.closer(fn)

	m.logger.Info("new GRPC server instance started",
		"address", p.Addr,
	)

	m.srv, err = protojson.Marshal(p)

	return m.srv, err
}

// Close the manager (and all managed plugins)
func (m *CoreManager) Close() (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	m.logger.Warn("closing the plugin manager")
	for _, c := range m.closers {
		if e := c(); err != nil {
			err = multierror.Append(err, e)
		}
	}
	return
}

var _ sdkcore.CorePluginManager = (*CoreManager)(nil)
