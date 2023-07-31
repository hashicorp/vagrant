// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package client

import (
	"github.com/hashicorp/vagrant/internal/runner"
)

// startRunner initializes and starts a local runner. If the returned
// runner is non-nil, you must call Close on it to clean up resources properly.
func (c *Client) startRunner() (*runner.Runner, error) {
	// Initialize our runner
	r, err := runner.New(
		runner.WithClient(c.client),
		runner.WithVagrantRubyRuntime(c.rubyRuntime),
		runner.WithLogger(c.logger),
		runner.ByIdOnly(),      // We'll direct target this
		runner.WithLocal(c.ui), // Local mode
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
