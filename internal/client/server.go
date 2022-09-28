package client

import (
	"context"
	"fmt"
	"io/fs"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/glebarez/sqlite"
	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/emptypb"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server"
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

	dataPath, err := paths.VagrantData()
	if err != nil {
		return
	}
	path := dataPath.Join("data.db").String()
	log.Debug("opening local mode DB", "path", path)

	// Open our database
	db, err := gorm.Open(sqlite.Open(path), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	db.Exec("PRAGMA foreign_keys = ON")
	if err != nil {
		return
	}

	// Create our server
	impl, err := singleprocess.New(
		singleprocess.WithDB(db),
		singleprocess.WithLogger(log.Named("singleprocess")),
	)
	if err != nil {
		log.Trace("failed singleprocess server setup", "error", err)
		return
	}

	// Prune old jobs before closing the database
	cleanups = append(cleanups, func() error {
		_, err := impl.PruneOldJobs(ctx, nil)
		return err
	})

	cleanups = append(cleanups, func() error {
		dbconn, err := db.DB()
		if err == nil {
			dbconn.Close()
		}
		return nil
	})

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

	// Have the defined cleanups run when the basis is closed
	for _, fn := range cleanups {
		c.Cleanup(fn)
	}

	_ = cancel // pacify vet lostcancel

	return client.Conn(), nil
}

// initVagrantRubyRuntime launches legacy vagrant as a gRPC server using the
// "serve" command.
//
// NOTE: We are assuming that the first executable we find in $PATH that is not
// _us_ is the legacy vagrant executable. It's up the packaging to ensure
// that is how things are set up.
func (c *Client) initVagrantRubyRuntime() (rubyRuntime plugin.ClientProtocol, err error) {
	var vagrantPath string
	vagrantPath, err = lookPathSkippingSelf("vagrant")
	if err != nil {
		return
	}
	config := serverclient.RubyVagrantPluginConfig(c.logger)
	config.Cmd = exec.Command(vagrantPath, "serve")
	rc := plugin.NewClient(config)
	if _, err = rc.Start(); err != nil {
		return
	}
	if rubyRuntime, err = rc.Client(); err != nil {
		return
	}

	// Send a request to the vagrant ruby runtime to shut itself down
	// NOTE: Closing the client when using the official package will not
	//       stop the process. This is because the package uses a custom
	//       wrapper for starting Vagrant which results in a different
	//       PID than what is originally started.
	c.Cleanup(func() error {
		vr, err := rubyRuntime.Dispense("vagrantrubyruntime")
		if err != nil {
			c.logger.Error("failed to dispense the vagrant ruby runtime",
				"error", err,
			)
			return err
		}
		vrc, ok := vr.(serverclient.RubyVagrantClient)
		if !ok {
			c.logger.Error("dispensed value is not a ruby runtime client")
			return fmt.Errorf("dispensed value is not a ruby vagrant client (%T)", vr)
		}

		return vrc.Stop()
	})

	// Close the ruby runtime client.
	c.Cleanup(func() error {
		return rubyRuntime.Close()
	})

	return
}

// negotiateApiVersion negotiates the API version to use and validates
// that we are compatible to talk to the server.
func (c *Client) negotiateApiVersion(ctx context.Context) error {
	c.logger.Trace("requesting version info from server")
	resp, err := c.client.GetVersionInfo(ctx, &emptypb.Empty{})
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

// lookPathSkippingSelf is a copy of exec.LookPath modified to skip the
// currently running executable.
func lookPathSkippingSelf(file string) (string, error) {
	myselfPath, err := os.Executable()
	if err != nil {
		return "", err
	}
	myself, err := os.Stat(myselfPath)
	if err != nil {
		return "", err
	}
	if strings.Contains(file, "/") {
		err := findExecutable(file, myself)
		if err == nil {
			return file, nil
		}
		return "", &exec.Error{Name: file, Err: err}
	}
	path := os.Getenv("PATH")
	for _, dir := range filepath.SplitList(path) {
		if dir == "" {
			// Unix shell semantics: path element "" means "."
			dir = "."
		}
		path := filepath.Join(dir, file)
		if err := findExecutable(path, myself); err == nil {
			return path, nil
		}
	}
	return "", &exec.Error{Name: file, Err: exec.ErrNotFound}
}

// findExecutableSkippingSelf is a copy of exec.findExecutable modified to skip
// the provided FileInfo. It's used to power lookPathSkippingSelf.
func findExecutable(file string, skip os.FileInfo) error {
	d, err := os.Stat(file)
	if err != nil {
		return err
	}
	if os.SameFile(d, skip) {
		return fs.ErrPermission
	}
	if m := d.Mode(); !m.IsDir() && m&0111 != 0 {
		return nil
	}
	return fs.ErrPermission
}
