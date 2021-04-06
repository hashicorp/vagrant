package client

import (
	"context"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Machine struct {
	ui terminal.UI

	project *Project
	machine *vagrant_server.Machine
	logger  hclog.Logger
}

func (m *Machine) UI() terminal.UI {
	return m.ui
}

func (m *Machine) Ref() *vagrant_server.Ref_Machine {
	return &vagrant_server.Ref_Machine{
		ResourceId: m.machine.ResourceId,
		Name:       m.machine.Name,
		Project:    m.project.Ref(),
	}
}

func (m *Machine) job() *vagrant_server.Job {
	job := m.project.job()
	job.Machine = m.Ref()
	return job
}

func (m *Machine) Close() error {
	return m.project.Close()
}

func (m *Machine) doJob(ctx context.Context, job *vagrant_server.Job) (*vagrant_server.Job_Result, error) {
	return m.project.doJob(ctx, job, m.ui)
}
