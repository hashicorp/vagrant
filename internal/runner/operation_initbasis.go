package runner

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (r *Runner) executeInitBasisOp(
	ctx context.Context,
	job *vagrant_server.Job,
	basis *core.Basis,
) (result *vagrant_server.Job_Result, err error) {
	_, ok := job.Operation.(*vagrant_server.Job_InitBasis)
	if !ok {
		panic("operation not expected type")
	}

	ref, ok := basis.Ref().(*vagrant_plugin_sdk.Ref_Basis)
	// x, err := basis.RunInit()
	result = &vagrant_server.Job_Result{
		Basis: &vagrant_server.Job_InitBasisResult{
			Basis: ref,
		},
	}
	return
}
