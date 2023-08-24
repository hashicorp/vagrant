package runner

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (r *Runner) executeInitProjectOp(
	ctx context.Context,
	job *vagrant_server.Job,
	project *core.Project,
) (result *vagrant_server.Job_Result, err error) {
	_, ok := job.Operation.(*vagrant_server.Job_InitProject)
	if !ok {
		panic("operation not expected type")
	}

	ref, ok := project.Ref().(*vagrant_plugin_sdk.Ref_Project)
	// x, err := basis.RunInit()
	result = &vagrant_server.Job_Result{
		Project: &vagrant_server.Job_InitProjectResult{
			Project: ref,
		},
	}
	return
}
