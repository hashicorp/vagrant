// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (s *service) SetConfig(
	ctx context.Context,
	req *vagrant_server.ConfigSetRequest,
) (*vagrant_server.ConfigSetResponse, error) {
	if err := s.state.ConfigSet(req.Variables...); err != nil {
		return nil, err
	}

	return &vagrant_server.ConfigSetResponse{}, nil
}

func (s *service) GetConfig(
	ctx context.Context,
	req *vagrant_server.ConfigGetRequest,
) (*vagrant_server.ConfigGetResponse, error) {
	vars, err := s.state.ConfigGet(req)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.ConfigGetResponse{Variables: vars}, nil
}
