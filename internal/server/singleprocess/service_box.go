// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"
)

func (s *service) ListBoxes(
	ctx context.Context,
	req *emptypb.Empty,
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
) (empt *emptypb.Empty, err error) {
	err = s.state.BoxDelete(req.Box)
	return &emptypb.Empty{}, nil
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
	result.LastUpdate = timestamppb.Now()
	if err := s.state.BoxPut(result); err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertBoxResponse{Box: result}, nil
}

func (s *service) FindBox(
	ctx context.Context,
	req *vagrant_server.FindBoxRequest,
) (*vagrant_server.FindBoxResponse, error) {
	result, err := s.state.BoxFind(req.Box)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.FindBoxResponse{Box: result}, nil
}
