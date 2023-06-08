package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/protobuf/types/known/emptypb"
)

func (s *service) UpsertBasis(
	ctx context.Context,
	req *vagrant_server.UpsertBasisRequest,
) (*vagrant_server.UpsertBasisResponse, error) {
	result, err := s.state.BasisPut(req.Basis)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertBasisResponse{Basis: result}, nil
}

func (s *service) GetBasis(
	ctx context.Context,
	req *vagrant_server.GetBasisRequest,
) (*vagrant_server.GetBasisResponse, error) {
	result, err := s.state.BasisGet(req.Basis)
	if err != nil {
		return nil, err
	}
	return &vagrant_server.GetBasisResponse{Basis: result}, nil
}

func (s *service) FindBasis(
	ctx context.Context,
	req *vagrant_server.FindBasisRequest,
) (*vagrant_server.FindBasisResponse, error) {
	result, err := s.state.BasisFind(req.Basis)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.FindBasisResponse{Basis: result}, nil
}

func (s *service) ListBasis(
	ctx context.Context,
	req *emptypb.Empty,
) (*vagrant_server.ListBasisResponse, error) {
	result, err := s.state.BasisList()
	if err != nil {
		return nil, err
	}
	all := make([]*vagrant_plugin_sdk.Ref_Basis, len(result))
	for i, v := range result {
		all[i] = v.ToProtoRef()
	}

	return &vagrant_server.ListBasisResponse{Basis: all}, nil
}
