package singleprocess

import (
	"context"
	"sync"

	"github.com/hashicorp/go-hclog"
	"gorm.io/gorm"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/server/singleprocess/state"
	"github.com/hashicorp/vagrant/internal/serverconfig"
)

// service implements the gRPC service for the server.
type service struct {
	// state is the state management interface that provides functions for
	// safely mutating server state.
	state *state.State

	// id is our unique server ID.
	id string

	// bgCtx is used for background tasks within the service. This is
	// cancelled when Close is called.
	bgCtx       context.Context
	bgCtxCancel context.CancelFunc

	// bgWg is incremented for every background goroutine that the
	// service starts up. When Close is called, we wait on this to ensure
	// that we fully shut down before returning.
	bgWg sync.WaitGroup

	vagrant_server.UnimplementedVagrantServer
}

// New returns a Vagrant server implementation that uses BoltDB plus
// in-memory locks to operate safely.
func New(opts ...Option) (vagrant_server.VagrantServer, error) {
	var s service
	var cfg config
	for _, opt := range opts {
		if err := opt(&s, &cfg); err != nil {
			return nil, err
		}
	}

	log := cfg.log
	if log == nil {
		log = hclog.L()
	}

	// Initialize our state
	st, err := state.New(log, cfg.db)
	if err != nil {
		log.Trace("state initialization failed", "error", err)
		return nil, err
	}
	s.state = st

	// Setup the background context that is used for internal tasks
	s.bgCtx, s.bgCtxCancel = context.WithCancel(context.Background())

	// Start out state pruning background goroutine. This calls
	// Prune on the state every 10 minutes.
	s.bgWg.Add(1)
	go s.runPrune(s.bgCtx, &s.bgWg, log.Named("prune"))

	return &s, nil
}

type config struct {
	db           *gorm.DB
	serverConfig *serverconfig.Config
	log          hclog.Logger
}

type Option func(*service, *config) error

// WithDB sets the Bolt DB for use with the server.
func WithDB(db *gorm.DB) Option {
	return func(s *service, cfg *config) error {
		cfg.db = db
		return nil
	}
}

// WithConfig sets the server config in use with this server.
func WithConfig(scfg *serverconfig.Config) Option {
	return func(s *service, cfg *config) error {
		cfg.serverConfig = scfg
		return nil
	}
}

// WithLogger sets the logger for use with the server.
func WithLogger(log hclog.Logger) Option {
	return func(s *service, cfg *config) error {
		cfg.log = log
		return nil
	}
}

var _ vagrant_server.VagrantServer = (*service)(nil)
