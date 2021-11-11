package singleprocess

import (
	"context"

	"github.com/golang/protobuf/ptypes/empty"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (s *service) ListBox(
	ctx context.Context,
	req *empty.Empty,
) (*vagrant_server.ListBoxesResponse, error) {
	result, err := s.state.BoxList()
	if err != nil {
		return nil, err
	}

	return &vagrant_server.ListBoxesResponse{Boxes: result}, nil
}

func (s *service) DeleteBox(
	ctx context.Context,
	req *vagrant_server.DeleteBoxRequest,
) (empt *empty.Empty, err error) {
	err = s.state.BoxDelete(req.Box)
	return
}

func (s *service) GetBox(
	ctx context.Context,
	req *vagrant_server.GetBoxRequest,
) (*vagrant_server.GetBoxResponse, error) {
	result, err := s.state.BoxGet(req.Box)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.GetBoxResponse{Box: result}, nil
}

func (s *service) UpsertBox(
	ctx context.Context,
	req *vagrant_server.UpsertBoxRequest,
) (*vagrant_server.UpsertBoxResponse, error) {
	result := req.Box
	if err := s.state.BoxPut(result); err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertBoxResponse{Box: result}, nil
}

func (s *service) FindBox(
	ctx context.Context,
	req *vagrant_server.FindBoxRequest,
) (*vagrant_server.FindBoxResponse, error) {
	result, err:= s.state.BoxFind(req.Box)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.FindBoxResponse{Box: result}, nil
}
