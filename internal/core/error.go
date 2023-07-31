// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"fmt"

	"google.golang.org/genproto/googleapis/rpc/status"
)

type CommandError interface {
	error
	ExitCode() int32
	Status() *status.Status
}

type runError struct {
	err      error
	exitCode int32
	status   *status.Status
}

// Error implements error
func (r *runError) Error() string {
	if r.err != nil {
		return r.err.Error()
	}
	return fmt.Sprintf("non-zero exit code: %d", r.exitCode)
}

// runError implements CommandError
func (r *runError) ExitCode() int32 {
	return r.exitCode
}

// runError implements CommandError
func (r *runError) Status() *status.Status {
	return r.status
}
