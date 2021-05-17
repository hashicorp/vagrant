package client

import (
	"context"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Target struct {
	ui terminal.UI

	project *Project
	target  *vagrant_server.Target
	logger  hclog.Logger
}

func (m *Target) UI() terminal.UI {
	return m.ui
}

func (m *Target) Ref() *vagrant_plugin_sdk.Ref_Target {
	return &vagrant_plugin_sdk.Ref_Target{
		ResourceId: m.target.ResourceId,
		Name:       m.target.Name,
		Project:    m.project.Ref(),
	}
}

func (m *Target) job() *vagrant_server.Job {
	job := m.project.job()
	job.Target = m.Ref()
	return job
}

func (m *Target) Close() error {
	return m.project.Close()
}

func (m *Target) doJob(ctx context.Context, job *vagrant_server.Job) (*vagrant_server.Job_Result, error) {
	return m.project.doJob(ctx, job, m.ui)
}
