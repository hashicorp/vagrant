package singleprocess

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/glebarez/sqlite"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"

	"github.com/hashicorp/vagrant/internal/server"
	pb "github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// TestServer starts a singleprocess server and returns the connected client.
// We use t.Cleanup to ensure resources are automatically cleaned up.
func TestServer(t testing.T, opts ...Option) *serverclient.VagrantClient {
	return server.TestServer(t, TestImpl(t, opts...))
}

// TestImpl returns the vagrant server implementation. This can be used
// with server.TestServer. It is easier to just use TestServer directly.
func TestImpl(t testing.T, opts ...Option) pb.VagrantServer {
	impl, err := New(append(
		[]Option{WithDB(testDB(t))},
		opts...,
	)...)
	require.NoError(t, err)
	return impl
}

// // TestWithURLService is an Option for testing only that creates an
// // in-memory URL service server. This requires access to an external
// // postgres server.
// //
// // If out is non-nil, it will be written to with the DevSetup info.
// func TestWithURLService(t testing.T, out *hzntest.DevSetup) Option {
// 	// Create the test server. On test end we close the channel which quits
// 	// the Horizon test server.
// 	setupCh := make(chan *hzntest.DevSetup, 1)
// 	closeCh := make(chan struct{})
// 	t.Cleanup(func() { close(closeCh) })
// 	go hzntest.Dev(t, func(setup *hzntest.DevSetup) {
// 		hubclient, err := hznhub.NewHub(hclog.L(), setup.ControlClient, setup.HubToken)
// 		require.NoError(t, err)
// 		go hubclient.Run(context.Background(), setup.ClientListener)

// 		setupCh <- setup
// 		<-closeCh
// 	})
// 	setup := <-setupCh

// 	// Make our test registration API
// 	wphzndata := wphzn.TestServer(t,
// 		wphzn.WithNamespace("/"),
// 		wphzn.WithHznControl(setup.MgmtClient),
// 	)

// 	// Get our account token.
// 	wpaccountResp, err := wphzndata.Client.RegisterGuestAccount(
// 		context.Background(),
// 		&wphznpb.RegisterGuestAccountRequest{
// 			ServerId: "A",
// 		},
// 	)
// 	require.NoError(t, err)

// 	// We need to get the account since that is what we need to query with
// 	tokenInfo, err := setup.MgmtClient.GetTokenPublicKey(context.Background(), &hznpb.Noop{})
// 	require.NoError(t, err)
// 	token, err := hzntoken.CheckTokenED25519(wpaccountResp.Token, tokenInfo.PublicKey)
// 	require.NoError(t, err)
// 	setup.Account = token.Account()

// 	// Copy our setup config
// 	if out != nil {
// 		*out = *setup
// 	}

// 	return func(s *service, cfg *config) error {
// 		if cfg.serverConfig == nil {
// 			cfg.serverConfig = &serverconfig.Config{}
// 		}

// 		cfg.serverConfig.URL = &serverconfig.URL{
// 			Enabled:              true,
// 			APIAddress:           wphzndata.Addr,
// 			APIInsecure:          true,
// 			APIToken:             wpaccountResp.Token,
// 			ControlAddress:       fmt.Sprintf("dev://%s", setup.HubAddr),
// 			AutomaticAppHostname: true,
// 		}

// 		return nil
// 	}
// }

// TestRunner registers a runner and returns the ID and a function to
// deregister the runner. This uses t.Cleanup so that the runner will always
// be deregistered on test completion.
func TestRunner(t testing.T, client pb.VagrantClient, r *pb.Runner) (string, func()) {
	require := require.New(t)
	ctx := context.Background()

	// Get the runner
	if r == nil {
		r = &pb.Runner{}
	}
	id, err := server.Id()
	require.NoError(err)
	require.NoError(mergo.Merge(r, &pb.Runner{Id: id}))

	// Open the config stream
	stream, err := client.RunnerConfig(ctx)
	require.NoError(err)
	t.Cleanup(func() { stream.CloseSend() })

	// Register
	require.NoError(err)
	require.NoError(stream.Send(&pb.RunnerConfigRequest{
		Event: &pb.RunnerConfigRequest_Open_{
			Open: &pb.RunnerConfigRequest_Open{
				Runner: r,
			},
		},
	}))

	// Wait for first message to confirm we're registered
	_, err = stream.Recv()
	require.NoError(err)

	return id, func() { stream.CloseSend() }
}

// TestBasis creates the basis in the DB.
func TestBasis(t testing.T, client pb.VagrantClient, ref *pb.Basis) {
	td := testTempDir(t)
	defaultBasis := &pb.Basis{
		Name: "test",
		Path: td,
	}

	require.NoError(t, mergo.Merge(ref, defaultBasis))

	_, err := client.UpsertBasis(context.Background(), &pb.UpsertBasisRequest{
		Basis: ref,
	})
	require.NoError(t, err)
}

func testDB(t testing.T) *gorm.DB {
	t.Helper()

	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"), &gorm.Config{})
	require.NoError(t, err)
	t.Cleanup(func() {
		d, err := db.DB()
		if err != nil {
			d.Close()
		}
	})

	return db
}

func testTempDir(t testing.T) string {
	dir, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}
