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
)

func TestServiceBox(t *testing.T) {
	ctx := context.Background()

	t.Run("set and get", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		b := testBox()
		resp, err := client.UpsertBox(ctx, &vagrant_server.UpsertBoxRequest{
			Box: b,
		})
		require.NoError(err)
		require.NotNil(resp)
		require.Equal(b.ResourceId, resp.Box.ResourceId)

		// should be able to get by ID
		getResp, err := client.GetBox(ctx, &vagrant_server.GetBoxRequest{
			Box: &vagrant_plugin_sdk.Ref_Box{ResourceId: b.ResourceId},
		})
		require.NoError(err)
		require.NotNil(getResp)
		require.Equal(b.Provider, getResp.Box.Provider)
		require.Equal(b.Name, getResp.Box.Name)
		require.Equal(b.Version, getResp.Box.Version)

	})

	t.Run("find", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		// first insert
		b := testBox()
		_, err = client.UpsertBox(ctx, &vagrant_server.UpsertBoxRequest{
			Box: b,
		})
		require.NoError(err)

		// then find it
		findResp, err := client.FindBox(ctx, &vagrant_server.FindBoxRequest{
			Box: &vagrant_plugin_sdk.Ref_Box{Name: b.Name},
		})
		require.NoError(err)
		require.NotNil(findResp)
		require.Equal(b.ResourceId, findResp.Box.ResourceId)

		// then delete it and ensure it's no longer found
		_, err = client.DeleteBox(ctx, &vagrant_server.DeleteBoxRequest{
			Box: &vagrant_plugin_sdk.Ref_Box{ResourceId: b.ResourceId},
		})
		require.NoError(err)

		refindResp, err := client.FindBox(ctx, &vagrant_server.FindBoxRequest{
			Box: &vagrant_plugin_sdk.Ref_Box{Name: b.Name},
		})
		require.NoError(err)
		require.NotNil(refindResp)
	})

	t.Run("reasonable errors: get not found", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		_, err = client.GetBox(ctx, &vagrant_server.GetBoxRequest{
			Box: &vagrant_plugin_sdk.Ref_Box{ResourceId: "idontexist"},
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

// minimum box valid to save
func testBox() *vagrant_server.Box {
	return &vagrant_server.Box{
		Provider: "virtualbox",
		Name:     "test/box",
		Version:  "1.2.3",
		// Id must be Name-Provider-Version because indexing assumes it is
		// (the NewBox constructor normally generates this in core/box)
		ResourceId: "test/box-1.2.3-virtualbox",
	}
}
