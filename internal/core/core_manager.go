package core

import (
	"sync"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"google.golang.org/protobuf/encoding/protojson"
)

type CoreManager struct {
	closers []func() error // List of functions to execute on close
	logger  hclog.Logger   // Logger for the manager
	m       sync.Mutex
	srv     []byte // Marshalled proto message for plugin manager
}

func (m *CoreManager) closer(f func() error) {
	m.closers = append(m.closers, f)
}

func (m *CoreManager) GetPlugin(pluginType sdkcore.Type) (plg interface{}, err error) {
	switch pluginType {
	case sdkcore.BoxMetadataType:
		return &BoxMetadata{}, nil
	}
	return
}

func (m *CoreManager) Servinfo(broker *plugin.GRPCBroker) ([]byte, error) {
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

var _ sdkcore.CorePluginManager = (*CoreManager)(nil)
