package ptypes

import (
	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestServerConfig(t testing.T, src *vagrant_server.ServerConfig) *vagrant_server.ServerConfig {
	t.Helper()

	if src == nil {
		src = &vagrant_server.ServerConfig{}
	}

	require.NoError(t, mergo.Merge(src, &vagrant_server.ServerConfig{
		AdvertiseAddrs: []*vagrant_server.ServerConfig_AdvertiseAddr{
			{
				Addr: "127.0.0.1",
			},
		},
	}))

	return src
}

// ValidateServerConfig validates the server config structure.
func ValidateServerConfig(c *vagrant_server.ServerConfig) error {
	return validation.ValidateStruct(c,
		validation.Field(&c.AdvertiseAddrs, validation.Required, validation.Length(1, 1)),
	)
}
