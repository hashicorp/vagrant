package client

import (
	"context"
	"errors"
	"io"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	vconfig "github.com/hashicorp/vagrant-plugin-sdk/config"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/runner"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

var (
	NotFoundErr = errors.New("failed to locate requested resource")
)

type Client struct {
	config      *config.Config
	cleanup     cleanup.Cleanup
	client      *serverclient.VagrantClient
	ctx         context.Context
	localRunner bool
	localServer bool
	logger      hclog.Logger
	rubyRuntime plugin.ClientProtocol
	runner      *runner.Runner
	runnerRef   *vagrant_server.Ref_Runner
	ui          terminal.UI
}

func New(ctx context.Context, opts ...Option) (c *Client, err error) {
	c = &Client{
		cleanup: cleanup.New(),
		ctx:     ctx,
		logger:  hclog.L().Named("vagrant.client"),
		runnerRef: &vagrant_server.Ref_Runner{
			Target: &vagrant_server.Ref_Runner_Any{
				Any: &vagrant_server.Ref_RunnerAny{},
			},
		},
	}

	// If an error was encountered, ensure that
	// we return back a nil value for the client
	defer func() {
		if err != nil {
			c = nil
		}
	}()

	// Apply any provided options
	var cfg clientConfig
	for _, opt := range opts {
		if e := opt(c, &cfg); e != nil {
			err = multierror.Append(err, e)
		}
	}
	if err != nil {
		return
	}

	// If no UI is configured, create a default
	if c.ui == nil {
		c.ui = terminal.ConsoleUI(ctx)
	}

	// If no client is configured, establish a new connection
	// or spin up an in-process server
	if c.client == nil {
		conn, err := c.initServerClient(context.Background(), &cfg)
		if err != nil {
			c.logger.Error("failed to establish server connection",
				"error", err)

			return nil, err
		}
		c.client = serverclient.WrapVagrantClient(conn)
		c.logger.Info("established connection to vagrant server")
	} else {
		c.logger.Warn("using provided client for vagrant server connection")
	}

	// Negotiate the version
	if err = c.negotiateApiVersion(ctx); err != nil {
		return
	}

	// If no Ruby runtime is configured, start one
	if c.rubyRuntime == nil {
		if c.rubyRuntime, err = c.initVagrantRubyRuntime(); err != nil {
			c.logger.Error("failed to start vagrant ruby runtime",
				"error", err)

			return
		}
	}

	// If we are using a local runner, spin it up
	if c.localRunner {
		c.runner, err = c.startRunner()
		if err != nil {
			return
		}
		c.logger.Info("started local runner",
			"runner-id", c.runner.Id())

		// Set our local runner as the target
		c.runnerRef.Target = &vagrant_server.Ref_Runner_Id{
			Id: &vagrant_server.Ref_RunnerId{
				Id: c.runner.Id(),
			},
		}

		// Prepend our runner cleanup so that it
		// can properly shutdown everything before
		// the server is halted if we are running
		// a local server
		c.cleanup.Prepend(func() error {
			c.logger.Info("stopping local runner",
				"runner-id", c.runner.Id())

			return c.runner.Close()
		})
	}

	return
}

func (c *Client) LoadBasis(n string) (*Basis, error) {
	var basis *vagrant_server.Basis
	p, err := paths.NamedVagrantConfig(n)
	if err != nil {
		return nil, err
	}

	result, err := c.client.FindBasis(
		c.ctx,
		&vagrant_server.FindBasisRequest{
			Basis: &vagrant_server.Basis{
				Name: n,
				Path: p.String(),
			},
		},
	)

	if err != nil {
		if status.Code(err) != codes.NotFound {
			return nil, err
		}
		uresult, err := c.client.UpsertBasis(
			c.ctx,
			&vagrant_server.UpsertBasisRequest{
				Basis: &vagrant_server.Basis{
					Name: n,
					Path: p.String(),
				},
			},
		)
		if err != nil {
			return nil, err
		}
		basis = uresult.Basis
	} else {
		basis = result.Basis
	}

	return &Basis{
		basis:   basis,
		client:  c,
		ctx:     c.ctx,
		logger:  c.logger.Named("basis"),
		path:    p,
		ui:      c.ui,
		vagrant: c.client,
	}, nil
}

// Close the client and call any cleanup functions
// that have been defined
func (c *Client) Close() (err error) {
	return c.cleanup.Close()
}

func (c *Client) Cleanup(fn cleanup.CleanupFn) {
	c.cleanup.Do(fn)
}

func (c *Client) UI() terminal.UI {
	return c.ui
}

type clientConfig struct {
	connectOpts []serverclient.ConnectOption
}

type Option func(*Client, *clientConfig) error

// WithClient sets the client directly. In this case, the runner won't
// attempt any connection at all regardless of other configuration (env
// vars or vagrant config file). This will be used.
func WithClient(client *serverclient.VagrantClient) Option {
	return func(c *Client, cfg *clientConfig) error {
		if client != nil {
			c.client = client
		}
		return nil
	}
}

// WithClientConnect specifies the options for connecting to a client.
// If WithClient is specified, that client is always used.
//
// If WithLocal is set and no client is specified and no server creds
// can be found, then an in-process server will be created.
func WithClientConnect(opts ...serverclient.ConnectOption) Option {
	return func(_ *Client, cfg *clientConfig) error {
		cfg.connectOpts = opts
		return nil
	}
}

// WithLocal puts the client in local exec mode. In this mode, the client
// will spin up a per-operation runner locally and reference the local on-disk
// data for all operations.
func WithLocal() Option {
	return func(c *Client, cfg *clientConfig) error {
		c.localRunner = true
		return nil
	}
}

// WithLogger sets the logger for the client.
func WithLogger(log hclog.Logger) Option {
	return func(c *Client, cfg *clientConfig) error {
		c.logger = log
		return nil
	}
}

// WithUI sets the UI to use for the client.
func WithUI(ui terminal.UI) Option {
	return func(c *Client, cfg *clientConfig) error {
		c.ui = ui
		return nil
	}
}

// Register cleanup callback
func WithCleanup(f func() error) Option {
	return func(c *Client, cfg *clientConfig) error {
		c.Cleanup(f)
		return nil
	}
}

func WithConfig(cfg *config.Config) Option {
	return func(c *Client, _ *clientConfig) error {
		c.config = cfg
		return nil
	}
}

// Load a Vagrantfile
func LoadVagrantfile(
	file path.Path, // path to the Vagrantfile
	l hclog.Logger, // logger
	c serverclient.RubyVagrantClient, // vagrant ruby runtime for ruby based Vagrantfiles
) (p *vagrant_server.Vagrantfile, err error) {
	var v *vconfig.Vagrantfile

	p = &vagrant_server.Vagrantfile{}
	format := vconfig.JSON
	protoFormat := vagrant_server.Vagrantfile_JSON

	// We support three types of Vagrantfiles:
	//   * Ruby (original)
	//   * HCL
	//   * JSON (which is HCL in JSON form)
	ext := filepath.Ext(file.String())
	if ext == ".hcl" {
		format = vconfig.HCL
		protoFormat = vagrant_server.Vagrantfile_HCL
	}

	switch ext {
	case ".hcl", ".json":
		f, err := os.Open(file.String())
		if err != nil {
			return nil, err
		}
		p.Raw, err = io.ReadAll(f)
		if err != nil {
			return nil, err
		}

		v, err = vconfig.LoadVagrantfile(p.Raw, file.String(), format)
		if err != nil {
			return nil, err
		}
		if p.Unfinalized, err = vconfig.EncodeVagrantfile(v); err != nil {
			return nil, err
		}
	default:
		p.Unfinalized, err = c.ParseVagrantfile(file.String())
		if err != nil {
			l.Error("failed to parse vagrantfile",
				"error", err,
			)
			return nil, err
		}
		l.Info("initial vagrantfile value set",
			"path", file.String(),
			"value", p.Unfinalized,
		)
		protoFormat = vagrant_server.Vagrantfile_RUBY
	}
	p.Path = &vagrant_plugin_sdk.Args_Path{Path: file.String()}
	p.Format = protoFormat

	return
}
