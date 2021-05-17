package client

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/server/logviewer"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (b *Basis) Validate(ctx context.Context, op *vagrant_server.Job_ValidateOp) (*vagrant_server.Job_ValidateResult, error) {
	if op == nil {
		op = &vagrant_server.Job_ValidateOp{}
	}

	// Validate our job
	job := b.job()
	job.Operation = &vagrant_server.Job_Validate{
		Validate: op,
	}

	// Execute it
	result, err := b.doJob(ctx, job, nil)
	if err != nil {
		return nil, err
	}

	return result.Validate, nil
}

func (b *Basis) Commands(ctx context.Context, op *vagrant_server.Job_InitOp) (*vagrant_server.Job_InitResult, error) {
	if op == nil {
		op = &vagrant_server.Job_InitOp{}
	}

	job := b.job()
	job.Operation = &vagrant_server.Job_Init{
		Init: op,
	}

	result, err := b.doJob(ctx, job, nil)

	if err != nil {
		return nil, err
	}

	return result.Init, nil
}

func (b *Basis) Task(ctx context.Context, op *vagrant_server.Job_RunOp) (*vagrant_server.Job_RunResult, error) {
	if op == nil {
		op = &vagrant_server.Job_RunOp{}
	}

	job := b.job()
	job.Operation = &vagrant_server.Job_Run{
		Run: op,
	}

	result, err := b.doJob(ctx, job, nil)

	return result.Run, err
}

func (p *Project) Task(ctx context.Context, op *vagrant_server.Job_RunOp) (*vagrant_server.Job_RunResult, error) {
	if op == nil {
		op = &vagrant_server.Job_RunOp{}
	}

	job := p.job()
	job.Operation = &vagrant_server.Job_Run{
		Run: op,
	}

	result, err := p.doJob(ctx, job, nil)

	return result.Run, err
}

func (m *Target) Task(ctx context.Context, op *vagrant_server.Job_RunOp) (*vagrant_server.Job_RunResult, error) {
	if op == nil {
		op = &vagrant_server.Job_RunOp{}
	}

	job := m.job()
	job.Operation = &vagrant_server.Job_Run{
		Run: op,
	}

	result, err := m.doJob(ctx, job)
	if err != nil {
		return nil, err
	}

	return result.Run, err
}

func (b *Basis) Auth(ctx context.Context, op *vagrant_server.Job_AuthOp) (*vagrant_server.Job_AuthResult, error) {
	if op == nil {
		op = &vagrant_server.Job_AuthOp{}
	}

	// Auth our job
	job := b.job()
	job.Operation = &vagrant_server.Job_Auth{
		Auth: op,
	}

	// Execute it
	result, err := b.doJob(ctx, job, nil)
	if err != nil {
		return nil, err
	}

	return result.Auth, nil
}

func (b *Basis) Docs(ctx context.Context, op *vagrant_server.Job_DocsOp) (*vagrant_server.Job_DocsResult, error) {
	if op == nil {
		op = &vagrant_server.Job_DocsOp{}
	}

	job := b.job()
	job.Operation = &vagrant_server.Job_Docs{
		Docs: op,
	}

	// Execute it
	result, err := b.doJob(ctx, job, nil)
	if err != nil {
		return nil, err
	}

	return result.Docs, nil
}

func (b *Basis) Logs(ctx context.Context) (component.LogViewer, error) {
	log := b.logger.Named("logs")

	// First we attempt to query the server for logs for this deployment.
	log.Info("requesting log stream")
	client, err := b.client.GetLogStream(ctx, &vagrant_server.GetLogStreamRequest{
		Scope: &vagrant_server.GetLogStreamRequest_Basis{
			Basis: b.Ref(),
		},
	})
	if err != nil {
		return nil, err
	}

	// Build our log viewer
	return &logviewer.Viewer{Stream: client}, nil
}
