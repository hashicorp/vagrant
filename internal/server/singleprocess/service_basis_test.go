// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package singleprocess

import (
	"context"
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
)

func TestServiceBasis(t *testing.T) {
	ctx := context.Background()

	t.Run("set and get", func(t *testing.T) {
		require := require.New(t)
		client := TestServer(t)

		resp, err := client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
				Path: "/dev/null",
			},
		})
		require.NoError(err)
		require.NotNil(resp)
		require.NotEmpty(resp.Basis.ResourceId)
		require.Equal("mybasis", resp.Basis.Name)

		getResp, err := client.GetBasis(ctx, &vagrant_server.GetBasisRequest{
			Basis: &vagrant_plugin_sdk.Ref_Basis{
				ResourceId: resp.Basis.ResourceId,
			},
		})
		require.NoError(err)
		require.NotNil(getResp)
		require.Equal("mybasis", getResp.Basis.Name)
	})

	t.Run("find and list", func(t *testing.T) {
		require := require.New(t)
		client := TestServer(t)

		// first insert
		_, err := client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
				Path: "/dev/null",
			},
		})
		require.NoError(err)

		// then find it
		findResp, err := client.FindBasis(ctx, &vagrant_server.FindBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
			},
		})
		require.NoError(err)
		require.NotNil(findResp)
		require.Equal("mybasis", findResp.Basis.Name)

		// then ensure it shows up in a list
		listResp, err := client.ListBasis(ctx, &emptypb.Empty{})
		require.NoError(err)
		require.NotNil(listResp)
		require.Len(listResp.Basis, 1)
	})

	t.Run("reasonable errors: get not found", func(t *testing.T) {
		require := require.New(t)
		client := TestServer(t)

		_, err := client.GetBasis(ctx, &vagrant_server.GetBasisRequest{
			Basis: &vagrant_plugin_sdk.Ref_Basis{
				ResourceId: "idontexist",
			},
		})
		require.Error(err)

		// we expect this to be a GRPC error with a not found code and a decent
		// message
		st, ok := status.FromError(err)
		require.Equal(ok, true)
		require.Equal(st.Code(), codes.NotFound)
		require.Contains(st.Message(), "not found")
	})
}
