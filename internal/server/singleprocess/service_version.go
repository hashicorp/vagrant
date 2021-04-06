package singleprocess

import (
	"context"

	"github.com/golang/protobuf/ptypes/empty"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (s *service) GetVersionInfo(
	ctx context.Context,
	req *empty.Empty,
) (*vagrant_server.GetVersionInfoResponse, error) {
	return &vagrant_server.GetVersionInfoResponse{
		Info: protocolversion.Current(),
	}, nil
}
