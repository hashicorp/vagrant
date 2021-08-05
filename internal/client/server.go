package client

import (
	"context"
	"net"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"

	"github.com/boltdb/bolt"
	"github.com/golang/protobuf/ptypes/empty"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// initServerClient will initialize a gRPC connection to the Vagrant server.
// This is called if a client wasn't explicitly given with WithClient.
//
// If a connection is successfully established, this will register connection
// closing and server cleanup with the Project cleanup function.
//
// This function will do one of two things:
//
//   1. If connection options were given, it'll attempt to connect to
//      an existing Vagrant server.
//
//   2. If WithLocal was specified and no connection addresses can be
//      found, this will spin up an in-memory server.
//
func (c *Client) initServerClient(ctx context.Context, cfg *clientConfig) (*grpc.ClientConn, error) {
	log := c.logger.ResetNamed("vagrant.server")

	// If we're local, then connection is optional.
	opts := cfg.connectOpts
	if true { // c.localServer {
		log.Trace("WithLocal set, server credentials optional")
		opts = append(opts, serverclient.Optional())
	}

	// Connect. If we're local, this is set as optional so conn may be nil
	log.Info("attempting to source credentials and connect")
	conn, err := serverclient.Connect(ctx, opts...)
	if err != nil {
		return nil, err
	}

	// If we established a connection
	if conn != nil {
		log.Debug("connection established with sourced credentials")
		c.Cleanup(func() error { return conn.Close() })
		return conn, nil
	}

	// No connection, meaning we have to spin up a local server. This
	// can only be reached if we specified "Optional" to serverclient
	// which is only possible if we configured this client to support local
	// mode.
	log.Info("no server credentials found, using in-memory local server")
	return c.initLocalServer(ctx)
}

// initLocalServer starts the local server and configures p.client to
// point to it. This also configures p.localClosers so that all the
// resources are properly cleaned up on Close.
//
// If this returns an error, all resources associated with this operation
// will be closed, but the project can retry.
func (c *Client) initLocalServer(ctx context.Context) (_ *grpc.ClientConn, err error) {
	log := c.logger.ResetNamed("vagrant.server")
	c.localServer = true

	// We use this pointer to accumulate things we need to clean up
	// in the case of an error. On success we nil this variable which
	// doesn't close anything.
	var cleanups []func() error

	// If we encounter an error force all the
	// local cleanups to run
	defer func() {
		if err != nil {
			for _, c := range cleanups {
				c()
			}
		}
	}()

	// TODO(spox): path to this
	path := filepath.Join("data.db")
	log.Debug("opening local mode DB", "path", path)

	// Open our database
	db, err := bolt.Open(path, 0600, &bolt.Options{
		Timeout: 1 * time.Second,
	})
	if err != nil {
		return
	}
	cleanups = append(cleanups, func() error { return db.Close() })

	// Create our server
	impl, err := singleprocess.New(
		singleprocess.WithDB(db),
		singleprocess.WithLogger(log.Named("singleprocess")),
	)
	if err != nil {
		log.Trace("failed singleprocess server setup", "error", err)
		return
	}

	// We listen on a random locally bound port
	// TODO: we should use Unix domain sockets if supported
	ln, err := net.Listen("tcp", "127.0.0.1:")
	if err != nil {
		return
	}
	cleanups = append(cleanups, func() error { return ln.Close() })

	// Create a new cancellation context so we can cancel in the case of an error
	ctx, cancel := context.WithCancel(ctx)
	defer func() {
		if err != nil {
			cancel()
		}
	}()

	// Run the server
	log.Info("starting built-in server for local operations", "addr", ln.Addr().String())
	go server.Run(
		server.WithContext(ctx),
		server.WithLogger(log),
		server.WithGRPC(ln),
		server.WithImpl(impl),
	)

	client, err := serverclient.NewVagrantClient(ctx, log, ln.Addr().String())
	if err != nil {
		return
	}

	// Setup our server config. The configuration is specifically set so
	// so that there is no advertise address which will disable the CEB
	// completely.
	_, err = client.SetServerConfig(ctx, &vagrant_server.SetServerConfigRequest{
		Config: &vagrant_server.ServerConfig{
			AdvertiseAddrs: []*vagrant_server.ServerConfig_AdvertiseAddr{
				{
					Addr: "",
				},
			},
		},
	})
	if err != nil {
		return
	}

	// Have the defined cleanups run when the basis is closed
	c.Cleanup(cleanups...)

	_ = cancel // pacify vet lostcancel

	return client.Conn(), nil
}

func (c *Client) initVagrantRubyRuntime() (rubyRuntime plugin.ClientProtocol, err error) {
	// TODO: Update for actual release usage. This is dev only now.
	_, this_dir, _, _ := runtime.Caller(0)
	cmd := exec.Command(
		"bundle", "exec", "vagrant", "serve",
	)
	cmd.Env = []string{
		"BUNDLE_GEMFILE=" + filepath.Join(this_dir, "../../..", "Gemfile"),
		"VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true",
		"VAGRANT_LOG=debug",
		"VAGRANT_LOG_FILE=/tmp/vagrant.log",
	}

	config := serverclient.RubyVagrantPluginConfig(c.logger)
	config.Cmd = cmd
	rc := plugin.NewClient(config)
	if _, err = rc.Start(); err != nil {
		return
	}
	if rubyRuntime, err = rc.Client(); err != nil {
		return
	}

	// Ensure the plugin is halted when the basis is cleaned up
	c.Cleanup(func() error { return rubyRuntime.Close() })

	return
}

// negotiateApiVersion negotiates the API version to use and validates
// that we are compatible to talk to the server.
func (c *Client) negotiateApiVersion(ctx context.Context) error {
	c.logger.Trace("requesting version info from server")
	resp, err := c.client.GetVersionInfo(ctx, &empty.Empty{})
	if err != nil {
		return err
	}

	c.logger.Info("server version info",
		"version", resp.Info.Version,
		"api_min", resp.Info.Api.Minimum,
		"api_current", resp.Info.Api.Current,
		"entrypoint_min", resp.Info.Entrypoint.Minimum,
		"entrypoint_current", resp.Info.Entrypoint.Current,
	)

	vsn, err := protocolversion.Negotiate(protocolversion.Current().Api, resp.Info.Api)
	if err != nil {
		return err
	}

	c.logger.Info("negotiated api version", "version", vsn)
	return nil
}
