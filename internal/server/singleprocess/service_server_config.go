package singleprocess

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

type Targeter interface {
	ServerTarget() string
}

func (s *service) SetServerConfig(
	ctx context.Context,
	req *vagrant_server.SetServerConfigRequest,
) (*emptypb.Empty, error) {
	if err := serverptypes.ValidateServerConfig(req.Config); err != nil {
		return nil, status.Errorf(codes.FailedPrecondition, err.Error())
	}

	if err := s.state.ServerConfigSet(req.Config); err != nil {
		return nil, err
	}

	return &emptypb.Empty{}, nil
}

func (s *service) GetServerConfig(
	ctx context.Context,
	req *emptypb.Empty,
) (*vagrant_server.GetServerConfigResponse, error) {
	cfg, err := s.state.ServerConfigGet()
	if err != nil {
		return nil, err
	}

	return &vagrant_server.GetServerConfigResponse{Config: cfg}, nil
}
