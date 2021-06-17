package client

import (
	"context"
	"io"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	configpkg "github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type Basis struct {
	ui terminal.UI

	basis   *vagrant_server.Basis
	Project *Project

	client             *serverclient.VagrantClient
	vagrantRubyRuntime plugin.ClientProtocol
	logger             hclog.Logger
	runner             *vagrant_server.Ref_Runner
	cleanupFuncs       []func()

	config *configpkg.Config

	labels              map[string]string
	dataSourceOverrides map[string]string

	local       bool
	localServer bool // True when a local server is created
}

func New(ctx context.Context, opts ...Option) (basis *Basis, err error) {
	basis = &Basis{
		logger: hclog.L(),
		runner: &vagrant_server.Ref_Runner{
			Target: &vagrant_server.Ref_Runner_Any{
				Any: &vagrant_server.Ref_RunnerAny{},
			},
		},
	}

	// Apply any options
	var cfg config
	for _, opt := range opts {
		err := opt(basis, &cfg)
		if err != nil {
			return nil, err
		}
	}

	basis.logger = basis.logger.Named("basis")

	// If no internal basis was provided, set it up now
	if basis.basis == nil {
		vh, err := paths.VagrantHome()
		if err != nil {
			basis.logger.Error("failed to determine vagrant home", "error", err)
			return nil, err
		}
		basis.basis = &vagrant_server.Basis{
			Name: "default",
			Path: vh.String(),
		}
	}

	// If no UI was provided, create a default
	if basis.ui == nil {
		basis.ui = terminal.ConsoleUI(ctx)
	}

	// If a client was not provided, establish a new connection through
	// the serverclient package, or by spinning up an in-process server
	if basis.client == nil {
		basis.logger.Trace("no API client provided, initializing connection if possible")
		conn, err := basis.initServerClient(context.Background(), &cfg)
		if err != nil {
			return nil, err
		}
		basis.client = serverclient.WrapVagrantClient(conn)
	}

	// If the ruby runtime isn't provided, set it up
	if basis.vagrantRubyRuntime == nil {
		if basis.vagrantRubyRuntime, err = basis.initVagrantRubyRuntime(); err != nil {
			return nil, err
		}
	}

	// Negotiate the version
	if err := basis.negotiateApiVersion(ctx); err != nil {
		return nil, err
	}

	// Setup our basis within the database
	result, err := basis.client.FindBasis(
		context.Background(),
		&vagrant_server.FindBasisRequest{
			Basis: basis.basis,
		},
	)
	if err == nil && result.Found {
		basis.basis = result.Basis
		return basis, nil
	}

	basis.logger.Trace("failed to locate existing basis", "basis", basis.basis,
		"result", result, "error", err)

	uresult, err := basis.client.UpsertBasis(
		context.Background(),
		&vagrant_server.UpsertBasisRequest{
			Basis: basis.basis,
		},
	)

	if err != nil {
		return nil, err
	}

	basis.basis = uresult.Basis

	return basis, nil
}

func (b *Basis) LoadProject(p *vagrant_server.Project) (*Project, error) {
	result, err := b.client.FindProject(
		context.Background(),
		&vagrant_server.FindProjectRequest{
			Project: p,
		},
	)
	if err == nil && result.Found {
		b.Project = &Project{
			ui:      b.ui,
			basis:   b,
			project: result.Project,
			logger:  b.logger.Named("project"),
		}
		return b.Project, nil
	}

	b.logger.Trace("failed to locate existing project", "project", p,
		"result", result, "error", err)

	uresult, err := b.client.UpsertProject(
		context.Background(),
		&vagrant_server.UpsertProjectRequest{
			Project: p,
		},
	)
	if err != nil {
		return nil, err
	}

	b.Project = &Project{
		ui:      b.ui,
		project: uresult.Project,
		basis:   b,
		logger:  b.logger.Named("project"),
	}

	return b.Project, nil
}

func (b *Basis) Ref() *vagrant_plugin_sdk.Ref_Basis {
	return &vagrant_plugin_sdk.Ref_Basis{
		Name:       b.basis.Name,
		ResourceId: b.basis.ResourceId,
	}
}

func (b *Basis) Close() error {
	for _, f := range b.cleanupFuncs {
		f()
	}

	if closer, ok := b.ui.(io.Closer); ok {
		closer.Close()
	}
	return nil
}

// Client returns the raw Vagrant server API client.
func (b *Basis) Client() *serverclient.VagrantClient {
	return b.client
}

func (b *Basis) VagrantRubyRuntime() plugin.ClientProtocol {
	return b.vagrantRubyRuntime
}

// Local is true if the server is an in-process just-in-time server.
func (b *Basis) Local() bool {
	return b.localServer
}

func (b *Basis) UI() terminal.UI {
	return b.ui
}

func (b *Basis) cleanup(f func()) {
	b.cleanupFuncs = append(b.cleanupFuncs, f)
}

type config struct {
	connectOpts []serverclient.ConnectOption
}

type Option func(*Basis, *config) error

func WithBasis(pbb *vagrant_server.Basis) Option {
	return func(b *Basis, cfg *config) error {
		b.basis = pbb
		return nil
	}
}

func WithProject(p *Project) Option {
	return func(b *Basis, cfg *config) error {
		p.basis = b
		b.Project = p
		return nil
	}
}

// WithClient sets the client directly. In this case, the runner won't
// attempt any connection at all regardless of other configuration (env
// vars or vagrant config file). This will be used.
func WithClient(client *serverclient.VagrantClient) Option {
	return func(b *Basis, cfg *config) error {
		if client != nil {
			b.client = client
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
	return func(b *Basis, cfg *config) error {
		cfg.connectOpts = opts
		return nil
	}
}

// WithLocal puts the client in local exec mode. In this mode, the client
// will spin up a per-operation runner locally and reference the local on-disk
// data for all operations.
func WithLocal() Option {
	return func(b *Basis, cfg *config) error {
		b.local = true
		return nil
	}
}

// WithLogger sets the logger for the client.
func WithLogger(log hclog.Logger) Option {
	return func(b *Basis, cfg *config) error {
		b.logger = log
		return nil
	}
}

// WithUI sets the UI to use for the client.
func WithUI(ui terminal.UI) Option {
	return func(b *Basis, cfg *config) error {
		b.ui = ui
		return nil
	}
}

func WithCleanup(f func()) Option {
	return func(b *Basis, cfg *config) error {
		b.cleanup(f)
		return nil
	}
}

// WithSourceOverrides sets the data source overrides for queued jobs.
func WithSourceOverrides(m map[string]string) Option {
	return func(b *Basis, cfg *config) error {
		b.dataSourceOverrides = m
		return nil
	}
}

// WithLabels sets the labels or any operations.
func WithLabels(m map[string]string) Option {
	return func(b *Basis, cfg *config) error {
		b.labels = m
		return nil
	}
}

func WithConfig(c *configpkg.Config) Option {
	return func(b *Basis, cfg *config) error {
		b.config = c
		return nil
	}
}
