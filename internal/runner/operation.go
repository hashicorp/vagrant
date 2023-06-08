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

	log.Debug("processing operation ", "job", job)

	// Initial options for setting up the basis
	opts := []core.BasisOption{
		core.WithLogger(log),
		core.WithUI(ui),
		core.WithClient(r.client),
		core.WithJobInfo(jobInfo),
	}

	var scope Runs

	// Determine our basis reference
	var basisRef *vagrant_plugin_sdk.Ref_Basis
	var projectRef *vagrant_plugin_sdk.Ref_Project
	var targetRef *vagrant_plugin_sdk.Ref_Target
	switch s := job.Scope.(type) {
	case *vagrant_server.Job_Basis:
		basisRef = s.Basis
	case *vagrant_server.Job_Project:
		projectRef = s.Project
		basisRef = s.Project.Basis
	case *vagrant_server.Job_Target:
		targetRef = s.Target
		projectRef = s.Target.Project
		basisRef = s.Target.Project.Basis
	default:
		return nil, fmt.Errorf("invalid job scope %T (%#v)", job.Scope, job.Scope)
	}

	// Work backwards to setup the basis
	opts = append(opts, core.WithBasisRef(basisRef))

	// Load our basis
	b, err := r.factory.NewBasis(basisRef.ResourceId, opts...)
	if err != nil {
		return
	}

	scope = b

	// Lets check for a project, and if we have one,
	// load it up now
	var p *core.Project

	if projectRef != nil {
		p, err = r.factory.NewProject(
			core.WithBasis(b),
			core.WithProjectRef(projectRef),
		)
		if err != nil {
			return
		}

		scope = p
	}

	// Finally, if we have a target defined, load it up
	var m *core.Target

	if targetRef != nil {
		m, err = r.factory.NewTarget(
			core.WithProject(p),
			core.WithTargetRef(targetRef),
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

	case *vagrant_server.Job_Command:
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
