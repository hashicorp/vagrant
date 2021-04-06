package runner

import (
	"context"

	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Runs interface {
	Run(context.Context, *vagrant_server.Task) error
}

// Keeping this around as an example
func (r *Runner) executeRunOp(
	ctx context.Context,
	job *vagrant_server.Job,
	scope Runs,
) (result *vagrant_server.Job_Result, err error) {
	r.logger.Debug("starting execution of run operation", "scope", scope, "job", job)

	op, ok := job.Operation.(*vagrant_server.Job_Run) //op
	if !ok {
		// this shouldn't happen since the call to this function is gated
		// on the above type match.
		panic("operation not expected type")
	}

	var jrr vagrant_server.Job_RunResult
	jrr.Task = op.Run.Task

	err = scope.Run(ctx, op.Run.Task)

	r.logger.Debug("execution of run operation complete", "job", job, "error", err)

	jrr.RunResult = err == nil
	if err != nil {
		st, _ := status.FromError(err)
		jrr.RunError = st.Proto()
	}

	r.logger.Info("run operation is complete!")
	// TODO: Return machine
	return &vagrant_server.Job_Result{
		Run: &jrr,
	}, nil
}
