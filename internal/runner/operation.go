package runner

import (
	"context"
	"fmt"

	"github.com/hashicorp/go-hclog"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// executeJob executes an assigned job. This will source the data (if necessary),
// setup the project, execute the job, and return the outcome.
func (r *Runner) executeJob(
	ctx context.Context,
	log hclog.Logger,
	ui terminal.UI,
	job *vagrant_server.Job,
	wd string,
) (result *vagrant_server.Job_Result, err error) {
	// Build our job info
	jobInfo := &component.JobInfo{
		Id:    job.Id,
		Local: r.local,
	}

	log.Debug("processing operation ", "job", job, "basis", job.Basis,
		"project", job.Project, "target", job.Target)

	// Initial options for setting up the basis
	opts := []core.BasisOption{
		core.WithLogger(log),
		core.WithUI(ui),
		core.WithClient(r.client),
		core.WithJobInfo(jobInfo),
	}

	var scope Runs

	// Work backwards to setup the basis
	var ref *vagrant_plugin_sdk.Ref_Basis
	if job.Target != nil {
		ref = job.Target.Project.Basis
	} else if job.Project != nil {
		ref = job.Project.Basis
	} else {
		ref = job.Basis
	}
	opts = append(opts, core.WithBasisRef(ref))

	// Load our basis
	b, err := r.factory.NewBasis(ref.ResourceId, opts...)
	if err != nil {
		return
	}

	scope = b

	// Lets check for a project, and if we have one,
	// load it up now
	var p *core.Project

	if job.Project != nil {
		p, err = r.factory.NewProject(
			core.WithBasis(b),
			core.WithProjectRef(job.Project),
		)
		if err != nil {
			return
		}

		scope = p
	}

	// Finally, if we have a target defined, load it up
	var m *core.Target

	if job.Target != nil && p != nil && job.Target.Name != "" {
		m, err = r.factory.NewTarget(
			core.WithProject(p),
			core.WithTargetRef(job.Target),
		)
		if err != nil {
			return
		}

		scope = m
	}

	// Execute the operation
	log.Info("executing operation", "type", fmt.Sprintf("%T", job.Operation))
	switch job.Operation.(type) {
	case *vagrant_server.Job_Noop_:
		if r.noopCh != nil {
			select {
			case <-r.noopCh:
			case <-ctx.Done():
				return nil, ctx.Err()
			}
		}

		log.Debug("noop job success")
		return nil, nil

	case *vagrant_server.Job_Init:
		return r.executeInitOp(ctx, job, b)

	case *vagrant_server.Job_Run:
		log.Warn("running a run operation", "scope", scope, "job", job)
		return r.executeRunOp(ctx, job, scope)

	case *vagrant_server.Job_Auth:
		return r.executeAuthOp(ctx, log, job, p)

	case *vagrant_server.Job_Docs:
		return r.executeDocsOp(ctx, log, job, p)

	default:
		return nil, status.Errorf(codes.Aborted, "unknown operation %T", job.Operation)
	}
}
