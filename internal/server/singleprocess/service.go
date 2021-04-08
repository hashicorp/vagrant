package singleprocess

import (
	"github.com/boltdb/bolt"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
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

	vagrant_server.UnimplementedVagrantServer
	vagrant_plugin_sdk.UnimplementedMachineServiceServer
	vagrant_plugin_sdk.UnimplementedProjectServiceServer
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

	// If we don't have a server ID, set that.
	id, err := st.ServerIdGet()
	if err != nil {
		return nil, err
	}
	if id == "" {
		id, err = server.Id()
		if err != nil {
			return nil, err
		}

		if err := st.ServerIdSet(id); err != nil {
			return nil, err
		}
	}
	s.id = id

	// Set specific server config for the deployment entrypoint binaries
	if scfg := cfg.serverConfig; scfg != nil && scfg.CEBConfig != nil && scfg.CEBConfig.Addr != "" {
		// only one advertise address can be configured
		addr := &vagrant_server.ServerConfig_AdvertiseAddr{
			Addr:          scfg.CEBConfig.Addr,
			Tls:           scfg.CEBConfig.TLSEnabled,
			TlsSkipVerify: scfg.CEBConfig.TLSSkipVerify,
		}

		conf := &vagrant_server.ServerConfig{
			AdvertiseAddrs: []*vagrant_server.ServerConfig_AdvertiseAddr{addr},
		}

		if err := s.state.ServerConfigSet(conf); err != nil {
			return nil, err
		}
	}

	return &s, nil
}

type config struct {
	db           *bolt.DB
	serverConfig *serverconfig.Config
	log          hclog.Logger

	acceptUrlTerms bool
}

type Option func(*service, *config) error

// WithDB sets the Bolt DB for use with the server.
func WithDB(db *bolt.DB) Option {
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

func WithAcceptURLTerms(accept bool) Option {
	return func(s *service, cfg *config) error {
		cfg.acceptUrlTerms = true
		return nil
	}
}

var _ vagrant_server.VagrantServer = (*service)(nil)
