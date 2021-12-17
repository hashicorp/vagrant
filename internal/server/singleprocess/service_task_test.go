package singleprocess

import (
	"context"
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestServiceTask(t *testing.T) {
	ctx := context.Background()

	t.Run("set and get", func(t *testing.T) {
		require := require.New(t)
		t.Skip("We are leaving the Task Set/Get operations broken for now; see TODO in state.TaskPut")
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		// need a basis to have a project
		_, err = client.UpsertBasis(ctx, &vagrant_server.UpsertBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: "mybasis",
			},
		})
		require.NoError(err)

		resp, err := client.UpsertTask(ctx, &vagrant_server.UpsertTaskRequest{
			Task: &vagrant_server.Task{
				Scope: &vagrant_server.Task_Basis{Basis: &vagrant_plugin_sdk.Ref_Basis{Name: "mybasis"}},
				Task:  "mytask",
			},
		})
		require.NoError(err)
		require.NotNil(resp)
		require.NotEmpty(resp.Task.Id)
		require.Equal("mybasis", resp.Task.Task)

		getResp, err := client.GetTask(ctx, &vagrant_server.GetTaskRequest{
			Ref: &vagrant_server.Ref_Operation{Target: &vagrant_server.Ref_Operation_Id{Id: resp.Task.Id}},
		})
		require.NoError(err)
		require.NotNil(getResp)
		require.Equal("mytask", getResp.Task)
	})
}
