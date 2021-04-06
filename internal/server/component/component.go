// Package component has component implementations for the various
// resulting types.
package component

import (
	"github.com/golang/protobuf/proto"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func Deployment(v *vagrant_server.Deployment) component.Deployment {
	return &deployment{Value: v}
}

type deployment struct {
	Value *vagrant_server.Deployment
}

func (d *deployment) Proto() proto.Message { return d.Value.Deployment }

var (
	_ component.Deployment     = (*deployment)(nil)
	_ component.ProtoMarshaler = (*deployment)(nil)
)
