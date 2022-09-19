package singleprocess

import (
	"context"
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
)

func TestServiceProject(t *testing.T) {
	ctx := context.Background()

	t.Run("set and get", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		// need a basis to have a project
		basisResp, err := client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
				Path: "/path/basis",
			},
		})
		require.NoError(err)

		resp, err := client.UpsertProject(ctx, &vagrant_server.UpsertProjectRequest{
			Project: &vagrant_server.Project{
				Name:  "myproject",
				Path:  "/path/project",
				Basis: &vagrant_plugin_sdk.Ref_Basis{ResourceId: basisResp.Basis.ResourceId},
			},
		})
		require.NoError(err)
		require.NotNil(resp)
		require.NotEmpty(resp.Project.ResourceId)
		require.Equal("myproject", resp.Project.Name)

		getResp, err := client.GetProject(ctx, &vagrant_server.GetProjectRequest{
			Project: &vagrant_plugin_sdk.Ref_Project{
				ResourceId: resp.Project.ResourceId,
			},
		})
		require.NoError(err)
		require.NotNil(getResp)
		require.Equal("myproject", getResp.Project.Name)
	})

	t.Run("find and list", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		// first insert
		basisResp, err := client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis2",
				Path: "/path/basis2",
			},
		})
		require.NoError(err)

		resp, err := client.UpsertProject(ctx, &vagrant_server.UpsertProjectRequest{
			Project: &vagrant_server.Project{
				Name:  "myproject",
				Path:  "/path/project",
				Basis: &vagrant_plugin_sdk.Ref_Basis{ResourceId: basisResp.Basis.ResourceId},
			},
		})
		require.NoError(err)
		require.NotNil(resp)
		require.NotEmpty(resp.Project.ResourceId)
		require.Equal("myproject", resp.Project.Name)

		// see if we can find it by name
		findResp, err := client.FindProject(ctx, &vagrant_server.FindProjectRequest{
			Project: &vagrant_server.Project{
				Name:  "myproject",
				Basis: &vagrant_plugin_sdk.Ref_Basis{ResourceId: basisResp.Basis.ResourceId},
			},
		})
		require.NoError(err)
		require.NotNil(findResp)
		require.Equal(resp.Project.ResourceId, findResp.Project.ResourceId)
		require.Equal("myproject", findResp.Project.Name)

		// then ensure it shows up in a list
		listResp, err := client.ListProjects(ctx, &emptypb.Empty{})
		require.NoError(err)
		require.NotNil(listResp)
		require.Len(listResp.Projects, 1)
	})

	t.Run("reasonable errors: set without basis", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		_, err = client.UpsertProject(ctx, &vagrant_server.UpsertProjectRequest{
			Project: &vagrant_server.Project{
				Name: "ihavenobasis",
				Path: "/path/project/invalid",
			},
		})
		require.Error(err)
		require.Contains(err.Error(), "not found")
	})

	t.Run("reasonable errors: get not found", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		getResp, err := client.GetProject(ctx, &vagrant_server.GetProjectRequest{
			Project: &vagrant_plugin_sdk.Ref_Project{
				ResourceId: "idonotexist",
			},
		})
		require.Error(err)
		require.Nil(getResp)

		// we expect this to be a GRPC error with a not found code and a decent
		// message
		st, ok := status.FromError(err)
		require.Equal(ok, true)
		require.Equal(st.Code(), codes.NotFound)
		require.Contains(st.Message(), "not found")
	})
}
