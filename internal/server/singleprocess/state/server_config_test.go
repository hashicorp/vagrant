package state

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestServerConfig(t *testing.T) {
	t.Run("basic put and get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		// Set
		require.NoError(s.ServerConfigSet(&vagrant_server.ServerConfig{
			AdvertiseAddrs: []*vagrant_server.ServerConfig_AdvertiseAddr{},
		}))

		{
			// Get
			cfg, err := s.ServerConfigGet()
			require.NoError(err)
			require.NotNil(cfg)
			require.NotNil(cfg.AdvertiseAddrs)
		}

		// Unset
		require.NoError(s.ServerConfigSet(nil))

		{
			// Get
			cfg, err := s.ServerConfigGet()
			require.NoError(err)
			require.NotNil(cfg)
			require.Nil(cfg.AdvertiseAddrs)
		}
	})
}
