package core

import (
	"fmt"
)

type CommandError interface {
	error
	ExitCode() int32
}

type runError struct {
	err      error
	exitCode int32
}

// Error implements error
func (r *runError) Error() string {
	if r.err != nil {
		return r.err.Error()
	}
	return fmt.Sprintf("non-zero exit code: %d", r.exitCode)
}

func (r *runError) ExitCode() int32 {
	return r.exitCode
}
