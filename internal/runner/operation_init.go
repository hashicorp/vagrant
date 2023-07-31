// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package runner

import (
	"context"

	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (r *Runner) executeInitOp(
	ctx context.Context,
	job *vagrant_server.Job,
	basis *core.Basis,
) (result *vagrant_server.Job_Result, err error) {
	_, ok := job.Operation.(*vagrant_server.Job_Init)
	if !ok {
		panic("operation not expected type")
	}

	x, err := basis.RunInit()
	result = &vagrant_server.Job_Result{
		Init: x,
	}
	return
}
