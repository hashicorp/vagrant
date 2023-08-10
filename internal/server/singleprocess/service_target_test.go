// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package singleprocess

import (
	"context"
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/emptypb"
)

func TestServiceTarget(t *testing.T) {
	ctx := context.Background()

	t.Run("set and get", func(t *testing.T) {
		require := require.New(t)
		client := TestServer(t)

		// need a basis and a project to have a target
		basisResp, err := client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
				Path: "/dev/null",
			},
		})
		require.NoError(err)

		projectResp, err := client.UpsertProject(ctx, &vagrant_server.UpsertProjectRequest{
			Project: &vagrant_server.Project{
				Name:  "myproject",
				Path:  "/dev/null/project",
				Basis: &vagrant_plugin_sdk.Ref_Basis{ResourceId: basisResp.Basis.ResourceId},
			},
		})
		require.NoError(err)

		projectRef := &vagrant_plugin_sdk.Ref_Project{ResourceId: projectResp.Project.ResourceId}
		resp, err := client.UpsertTarget(ctx, &vagrant_server.UpsertTargetRequest{
			Target: &vagrant_server.Target{
				Name:    "mytarget",
				Project: projectRef,
			},
		})
		require.NoError(err)
		require.NotNil(resp)
		require.Equal("mytarget", resp.Target.Name)
	})

	t.Run("find and list and delete", func(t *testing.T) {
		require := require.New(t)
		client := TestServer(t)

		// first insert
		basisResp, err := client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
				Path: "/dev/null",
			},
		})
		require.NoError(err)

		projectResp, err := client.UpsertProject(ctx, &vagrant_server.UpsertProjectRequest{
			Project: &vagrant_server.Project{
				Name:  "myproject",
				Path:  "/dev/null/project",
				Basis: &vagrant_plugin_sdk.Ref_Basis{ResourceId: basisResp.Basis.ResourceId},
			},
		})

		projectRef := &vagrant_plugin_sdk.Ref_Project{ResourceId: projectResp.Project.ResourceId}
		_, err = client.UpsertTarget(ctx, &vagrant_server.UpsertTargetRequest{
			Target: &vagrant_server.Target{
				Name:    "mytarget",
				Project: projectRef,
			},
		})
		require.NoError(err)

		// see if we can find it by name & project
		findResp, err := client.FindTarget(ctx, &vagrant_server.FindTargetRequest{
			Target: &vagrant_server.Target{Project: projectRef, Name: "mytarget"},
		})
		require.NoError(err)
		require.NotNil(findResp)
		require.Equal("mytarget", findResp.Target.Name)

		// then ensure it shows up in a list
		listResp, err := client.ListTargets(ctx, &emptypb.Empty{})
		require.NoError(err)
		require.NotNil(listResp)
		require.Len(listResp.Targets, 1)

		// then delete it and the list should be empty
		_, err = client.DeleteTarget(ctx, &vagrant_server.DeleteTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: findResp.Target.ResourceId,
				Project:    projectRef,
			},
		})
		require.NoError(err)

		listResp, err = client.ListTargets(ctx, &emptypb.Empty{})
		require.NoError(err)
		require.NotNil(listResp)
		require.Len(listResp.Targets, 0)
	})

	t.Run("reasonable errors: set without project", func(t *testing.T) {
		require := require.New(t)
		client := TestServer(t)

		_, err := client.UpsertTarget(ctx, &vagrant_server.UpsertTargetRequest{
			Target: &vagrant_server.Target{
				Name: "ihavenoproject",
			},
		})
		require.Error(err)
		require.Contains(err.Error(), "not include parent")
	})
}
