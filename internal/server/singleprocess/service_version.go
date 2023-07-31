// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/protobuf/types/known/emptypb"
)

func (s *service) GetVersionInfo(
	ctx context.Context,
	req *emptypb.Empty,
) (*vagrant_server.GetVersionInfoResponse, error) {
	return &vagrant_server.GetVersionInfoResponse{
		Info: protocolversion.Current(),
	}, nil
}
