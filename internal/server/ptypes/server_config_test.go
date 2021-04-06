package ptypes

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestValidateServerConfig(t *testing.T) {
	cases := []struct {
		Name   string
		Modify func(*vagrant_server.ServerConfig)
		Error  string
	}{
		{
			"valid",
			nil,
			"",
		},

		{
			"no advertise addrs",
			func(c *vagrant_server.ServerConfig) { c.AdvertiseAddrs = nil },
			"advertise_addrs: cannot be blank",
		},

		{
			"two advertise addrs",
			func(c *vagrant_server.ServerConfig) {
				c.AdvertiseAddrs = append(c.AdvertiseAddrs, nil)
			},
			"advertise_addrs: the length must be exactly 1",
		},
	}

	for _, tt := range cases {
		t.Run(tt.Name, func(t *testing.T) {
			require := require.New(t)

			cfg := TestServerConfig(t, nil)
			if f := tt.Modify; f != nil {
				f(cfg)
			}

			err := ValidateServerConfig(cfg)
			if tt.Error == "" {
				require.NoError(err)
				return
			}

			require.Error(err)
			require.Contains(err.Error(), tt.Error)
		})
	}
}
