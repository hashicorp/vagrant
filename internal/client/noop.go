// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package client

import (
	"context"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// Noop executes a noop operation. This is primarily for testing but is
// exported since it has its uses in verifying a runner is functioning
// properly.
//
// A noop operation will exercise the full logic of queueing a job,
// assigning it to a runner, dequeueing as a runner, executing, etc. It will
// use real remote runners if the client is configured to do so.
func (c *Client) Noop(ctx context.Context) error {
	// Build our job
	job := c.job()
	job.Operation = &vagrant_server.Job_Noop_{
		Noop: &vagrant_server.Job_Noop{},
	}

	// Execute it
	_, err := c.doJob(ctx, job, c.ui)
	return err
}
