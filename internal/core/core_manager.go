package core

import (
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
)

type CoreManager struct {
}

func (m *CoreManager) GetPlugin(pluginType sdkcore.Type) (plg interface{}, err error) {
	switch pluginType {
	case sdkcore.BoxMetadataType:
		return &BoxMetadata{}, nil
	}
	return
}

var _ sdkcore.CorePluginManager = (*CoreManager)(nil)
