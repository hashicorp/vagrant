package client

import (
	"github.com/hashicorp/vagrant/internal/runner"
)

// startRunner initializes and starts a local runner. If the returned
// runner is non-nil, you must call Close on it to clean up resources properly.
func (b *Basis) startRunner() (*runner.Runner, error) {
	// Initialize our runner
	r, err := runner.New(
		runner.WithClient(b.client),
		runner.WithVagrantRubyRuntime(b.vagrantRubyRuntime),
		runner.WithLogger(b.logger),
		runner.ByIdOnly(),        // We'll direct target this
		runner.WithLocal(b.UI()), // Local mode
	)
	if err != nil {
		return nil, err
	}

	// Start the runner
	if err := r.Start(); err != nil {
		return nil, err
	}

	return r, nil
}
