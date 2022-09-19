package singleprocess

// import (
// 	"context"
// 	"testing"

// 	"github.com/stretchr/testify/require"

// 	"github.com/hashicorp/go-hclog"
// 	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
// 	"github.com/hashicorp/vagrant/internal/server"
// 	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
// 	"github.com/hashicorp/vagrant/internal/server/singleprocess/state"
// 	"github.com/hashicorp/vagrant/internal/serverconfig"
// )

// func TestServiceConfig(t *testing.T) {
// 	ctx := context.Background()

// 	// Create our server
// 	impl, err := New(WithDB(testDB(t)))
// 	require.NoError(t, err)
// 	client := server.TestServer(t, impl)

// 	// Simplify writing tests
// 	type (
// 		SReq = vagrant_server.ConfigSetRequest
// 		GReq = vagrant_server.ConfigGetRequest
// 	)

// 	Var := &vagrant_server.ConfigVar{
// 		Scope: &vagrant_server.ConfigVar_Project{
// 			Project: &vagrant_plugin_sdk.Ref_Project{
// 				ResourceId: "test",
// 				Name:       "bar",
// 			},
// 		},

// 		Name:  "DATABASE_URL",
// 		Value: "postgresql:///",
// 	}

// 	t.Run("set and get", func(t *testing.T) {
// 		require := require.New(t)

// 		// Create, should get an ID back
// 		resp, err := client.SetConfig(ctx, &SReq{Variables: []*vagrant_server.ConfigVar{Var}})
// 		require.NoError(err)
// 		require.NotNil(resp)

// 		// Let's write some data

// 		grep, err := client.GetConfig(ctx, &GReq{
// 			Scope: &vagrant_server.ConfigGetRequest_Project{
// 				Project: &vagrant_plugin_sdk.Ref_Project{
// 					ResourceId: "test",
// 					Name:       "bar",
// 				},
// 			},
// 		})
// 		require.NoError(err)
// 		require.NotNil(grep)

// 		require.Equal(1, len(grep.Variables))

// 		require.Equal(Var.Name, grep.Variables[0].Name)
// 		require.Equal(Var.Value, grep.Variables[0].Value)
// 	})
// }

// func TestServerConfigWithStartupConfig(t *testing.T) {

// 	cfg := &serverconfig.Config{
// 		CEBConfig: &serverconfig.CEBConfig{
// 			Addr:          "myendpoint",
// 			TLSEnabled:    false,
// 			TLSSkipVerify: true,
// 		},
// 	}

// 	db := testDB(t)
// 	// Create our server
// 	impl, err := New(
// 		WithDB(db),
// 		WithConfig(cfg),
// 	)
// 	require.NoError(t, err)
// 	_ = server.TestServer(t, impl)

// 	st, err := state.New(hclog.L(), db)
// 	require.NoError(t, err)

// 	t.Run("Check config defaults are set", func(t *testing.T) {
// 		require := require.New(t)

// 		retCfg, err := st.ServerConfigGet()
// 		require.NoError(err)
// 		require.NotNil(retCfg)

// 		addr := retCfg.AdvertiseAddrs[0]
// 		require.Equal(cfg.CEBConfig.Addr, addr.Addr)
// 		require.Equal(cfg.CEBConfig.TLSEnabled, addr.Tls)
// 		require.Equal(cfg.CEBConfig.TLSSkipVerify, addr.TlsSkipVerify)
// 	})
// }
// func TestServerConfigWithNoStartupConfig(t *testing.T) {

// 	db := testDB(t)
// 	// Create our server
// 	impl, err := New(
// 		WithDB(db),
// 	)
// 	require.NoError(t, err)
// 	_ = server.TestServer(t, impl)

// 	st, err := state.New(hclog.L(), db)
// 	require.NoError(t, err)

// 	t.Run("Check config defaults are not set", func(t *testing.T) {
// 		require := require.New(t)

// 		retCfg, err := st.ServerConfigGet()
// 		require.NoError(err)
// 		require.NotNil(retCfg)
// 		require.Len(retCfg.AdvertiseAddrs, 0)
// 	})
// }
