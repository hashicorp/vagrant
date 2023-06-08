package runner

import (
	"context"
	"fmt"

	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/genproto/googleapis/rpc/status"
	"google.golang.org/grpc/codes"
)

type Runs interface {
	Run(context.Context, *vagrant_server.Job_CommandOp) error
}

// Keeping this around as an example
func (r *Runner) executeRunOp(
	ctx context.Context,
	job *vagrant_server.Job,
	scope Runs,
) (result *vagrant_server.Job_Result, err error) {
	r.logger.Debug("starting execution of run operation", "scope", scope, "job", job)

	op, ok := job.Operation.(*vagrant_server.Job_Command) //op
	if !ok {
		// this shouldn't happen since the call to this function is gated
		// on the above type match.
		panic("operation not expected type")
	}

	var jrr vagrant_server.Job_CommandResult

	err = scope.Run(ctx, op.Command)

	r.logger.Debug("execution of run operation complete", "job", job, "error", err)

	jrr.RunResult = err == nil
	if err != nil {
		if cmdErr, ok := err.(core.CommandError); ok {
			jrr.RunError = err.(core.CommandError).Status()
			jrr.ExitCode = int32(cmdErr.ExitCode())
		} else {
			// If we have an error without a status we'll make one here
			jrr.RunError = &status.Status{
				Code:    int32(codes.Unknown),
				Message: fmt.Sprintf("Unexpected error from run operation: %s", err),
			}
			jrr.ExitCode = 1
		}

	}

	r.logger.Info("run operation is complete!")

	return &vagrant_server.Job_Result{
		Run: &jrr,
	}, nil
}
