package client

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/server/logviewer"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (c *Client) Validate(
	ctx context.Context,
	op *vagrant_server.Job_ValidateOp,
	mod JobModifier,
) (*vagrant_server.Job_ValidateResult, error) {
	if op == nil {
		op = &vagrant_server.Job_ValidateOp{}
	}

	// Validate our job
	job := c.job()
	job.Operation = &vagrant_server.Job_Validate{
		Validate: op,
	}
	if mod != nil {
		mod(job)
	}

	// Execute it
	result, err := c.doJob(ctx, job, c.ui)
	if err != nil {
		return nil, err
	}

	return result.Validate, nil
}

func (c *Client) Commands(
	ctx context.Context,
	op *vagrant_server.Job_InitOp,
	mod JobModifier,
) (*vagrant_server.Job_InitResult, error) {
	if op == nil {
		op = &vagrant_server.Job_InitOp{}
	}

	job := c.job()
	job.Operation = &vagrant_server.Job_Init{
		Init: op,
	}
	if mod != nil {
		mod(job)
	}

	result, err := c.doJob(ctx, job, c.ui)

	if err != nil {
		return nil, err
	}

	return result.Init, nil
}

func (c *Client) Command(
	ctx context.Context,
	op *vagrant_server.Job_CommandOp,
	mod JobModifier,
) (*vagrant_server.Job_CommandResult, error) {
	if op == nil {
		op = &vagrant_server.Job_CommandOp{}
	}

	job := c.job()
	job.Operation = &vagrant_server.Job_Command{
		Command: op,
	}
	if mod != nil {
		mod(job)
	}

	result, err := c.doJob(ctx, job, c.ui)
	if err != nil {
		return nil, err
	}

	return result.Run, nil
}

func (c *Client) Auth(
	ctx context.Context,
	op *vagrant_server.Job_AuthOp,
	mod JobModifier,
) (*vagrant_server.Job_AuthResult, error) {
	if op == nil {
		op = &vagrant_server.Job_AuthOp{}
	}

	// Auth our job
	job := c.job()
	job.Operation = &vagrant_server.Job_Auth{
		Auth: op,
	}
	if mod != nil {
		mod(job)
	}

	// Execute it
	result, err := c.doJob(ctx, job, c.ui)
	if err != nil {
		return nil, err
	}

	return result.Auth, nil
}

func (c *Client) Docs(
	ctx context.Context,
	op *vagrant_server.Job_DocsOp,
	mod JobModifier,
) (*vagrant_server.Job_DocsResult, error) {
	if op == nil {
		op = &vagrant_server.Job_DocsOp{}
	}

	job := c.job()
	job.Operation = &vagrant_server.Job_Docs{
		Docs: op,
	}
	if mod != nil {
		mod(job)
	}

	// Execute it
	result, err := c.doJob(ctx, job, c.ui)
	if err != nil {
		return nil, err
	}

	return result.Docs, nil
}

// TODO(spox): need to think about how to apply this
func (c *Client) Logs(ctx context.Context) (component.LogViewer, error) {
	log := c.logger.Named("logs")

	// First we attempt to query the server for logs for this deployment.
	log.Info("requesting log stream")
	client, err := c.client.GetLogStream(ctx, &vagrant_server.GetLogStreamRequest{
		Scope: &vagrant_server.GetLogStreamRequest_Basis{
			// Basis: b.Ref(),
		},
	})
	if err != nil {
		return nil, err
	}

	// Build our log viewer
	return &logviewer.Viewer{Stream: client}, nil
}
