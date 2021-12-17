package singleprocess

import (
	"context"
	"testing"

	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/types/known/emptypb"
)

func TestServiceServerConfig(t *testing.T) {
	ctx := context.Background()

	t.Run("set and get", func(t *testing.T) {
		require := require.New(t)
		db := testDB(t)
		impl, err := New(WithDB(db))
		require.NoError(err)
		client := server.TestServer(t, impl)

		resp, err := client.SetServerConfig(ctx, &vagrant_server.SetServerConfigRequest{
			Config: &vagrant_server.ServerConfig{
				AdvertiseAddrs: []*vagrant_server.ServerConfig_AdvertiseAddr{
					{Addr: "1.2.3.4"},
				},
			},
		})
		require.NoError(err)
		require.NotNil(resp)

		getResp, err := client.GetServerConfig(ctx, &emptypb.Empty{})
		require.NoError(err)
		require.NotNil(getResp)
		require.Equal("1.2.3.4", getResp.Config.AdvertiseAddrs[0].Addr)
	})
}
