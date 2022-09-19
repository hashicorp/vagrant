package singleprocess

import (
	"context"

	"google.golang.org/protobuf/types/known/emptypb"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// TODO: test
func (s *service) UpsertTarget(
	ctx context.Context,
	req *vagrant_server.UpsertTargetRequest,
) (*vagrant_server.UpsertTargetResponse, error) {
	result, err := s.state.TargetPut(req.Target)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertTargetResponse{Target: result}, nil
}

func (s *service) DeleteTarget(
	ctx context.Context,
	req *vagrant_server.DeleteTargetRequest,
) (empt *emptypb.Empty, err error) {
	err = s.state.TargetDelete(req.Target)
	return &emptypb.Empty{}, err
}

// TODO: test
func (s *service) GetTarget(
	ctx context.Context,
	req *vagrant_server.GetTargetRequest,
) (*vagrant_server.GetTargetResponse, error) {
	result, err := s.state.TargetGet(req.Target)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.GetTargetResponse{Target: result}, nil
}

func (s *service) FindTarget(
	ctx context.Context,
	req *vagrant_server.FindTargetRequest,
) (*vagrant_server.FindTargetResponse, error) {
	result, err := s.state.TargetFind(req.Target)
	if err != nil {
		return nil, err
	}
	return &vagrant_server.FindTargetResponse{Target: result}, nil
}

// TODO: test
func (s *service) ListTargets(
	ctx context.Context,
	req *emptypb.Empty,
) (*vagrant_server.ListTargetsResponse, error) {
	result, err := s.state.TargetList()
	if err != nil {
		return nil, err
	}

	return &vagrant_server.ListTargetsResponse{Targets: result}, nil
}
