package client

import (
	"context"
	"errors"
	"os"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	vagrant_plugin_sdk "github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// Project is the primary structure for interacting with a Vagrant
// server as a client. The client exposes a slightly higher level of
// abstraction over the server API for performing operations locally and
// remotely.
type Project struct {
	ui terminal.UI

	Machines []*Machine

	basis   *Basis
	project *vagrant_server.Project
	logger  hclog.Logger
}

func (p *Project) LoadMachine(m *vagrant_server.Machine) (*Machine, error) {
	machine, err := p.GetMachine(m.Name)
	if err == nil {
		return machine, nil
	}

	// Ensure the machine is set to this project
	m.Project = p.Ref()

	result, err := p.basis.client.FindMachine(
		context.Background(),
		&vagrant_server.FindMachineRequest{
			Machine: m,
		},
	)
	if err == nil && result.Found {
		machine := &Machine{
			ui:      p.UI(),
			project: p,
			machine: result.Machine,
			logger:  p.logger.Named("machine"),
		}
		p.Machines = append(p.Machines, machine)

		return machine, nil
	}

	p.logger.Trace("failed to locate existing machine", "machine", m,
		"result", result, "error", err)

	// TODO: set machine box from vagrant file

	if m.Datadir == nil {
		m.Datadir = p.GetDataDir()
	}

	if m.Provider == "" {
		m.Provider, err = p.GetDefaultProvider([]string{}, false, true)
	}

	uresult, err := p.basis.client.UpsertMachine(
		context.Background(),
		&vagrant_server.UpsertMachineRequest{
			Machine: m,
		},
	)
	if err != nil {
		return nil, err
	}

	machine = &Machine{
		ui:      p.UI(),
		project: p,
		machine: uresult.Machine,
		logger:  p.logger.Named("machine"),
	}

	p.Machines = append(p.Machines, machine)

	return machine, nil
}

// TODO: Determine default provider by implementing algorithm from
//       https://www.vagrantup.com/docs/providers/basic_usage#default-provider
//
//       Currently blocked on being able to parse Vagrantfile
func (p *Project) GetDefaultProvider(exclude []string, forceDefault bool, checkUsable bool) (provider string, err error) {
	defaultProvider := os.Getenv("VAGRANT_DEFAULT_PROVIDER")
	if defaultProvider != "" && forceDefault {
		return defaultProvider, nil
	}

	// HACK: This should throw an error if no default provider is found
	return "virtualbox", nil
}

func (p *Project) GetDataDir() *vagrant_plugin_sdk.Args_DataDir_Machine {
	// TODO: probably need to get datadir from the projet + basis

	root, _ := paths.VagrantHome()
	cacheDir := root.Join("cache")
	dataDir := root.Join("data")
	tmpDir := root.Join("tmp")

	return &vagrant_plugin_sdk.Args_DataDir_Machine{
		CacheDir: cacheDir.String(),
		DataDir:  dataDir.String(),
		RootDir:  root.String(),
		TempDir:  tmpDir.String(),
	}
}

func (p *Project) GetMachine(name string) (m *Machine, err error) {
	for _, m = range p.Machines {
		if m.Ref().Name == name {
			return
		}
	}
	return nil, errors.New("failed to locate requested machine")
}

func (p *Project) UI() terminal.UI {
	return p.ui
}

func (p *Project) Close() error {
	return p.basis.Close()
}

// Ref returns the raw Vagrant server API client.
func (p *Project) Ref() *vagrant_server.Ref_Project {
	return &vagrant_server.Ref_Project{
		Name:       p.project.Name,
		ResourceId: p.project.ResourceId,
		Basis:      p.basis.Ref(),
	}
}

// job is the same as Project.job except this also sets the application
// reference.
func (p *Project) job() *vagrant_server.Job {
	job := p.basis.job()
	job.Project = p.Ref()

	return job
}

func (p *Project) doJob(ctx context.Context, job *vagrant_server.Job, ui terminal.UI) (*vagrant_server.Job_Result, error) {
	if ui == nil {
		ui = p.ui
	}
	return p.basis.doJob(ctx, job, ui)
}
