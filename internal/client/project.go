package client

import (
	"context"
	"errors"
	"os"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	vagrant_plugin_sdk "github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	configpkg "github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// Project is the primary structure for interacting with a Vagrant
// server as a client. The client exposes a slightly higher level of
// abstraction over the server API for performing operations locally and
// remotely.
type Project struct {
	ui terminal.UI

	Targets []*Target

	basis   *Basis
	project *vagrant_server.Project
	logger  hclog.Logger
}

// Finds the Vagrantfile associated with the project
func (p *Project) LoadVagrantfiles() error {
	_, err := configpkg.FindPath(p.project.Path, configpkg.GetVagrantfileName())
	if err != nil {
		return err
	}
	// TODO:
	// 1) Send Vagrantfile found for this project to the ruby runtime to be parsed
	// 2) Upload the Vagrantfile to the vagrant server
	return nil
}

func (p *Project) LoadTarget(t *vagrant_server.Target) (*Target, error) {
	target, err := p.GetTarget(t.Name)
	if err == nil {
		return target, nil
	}

	// Ensure the machine is set to this project
	t.Project = p.Ref()

	result, err := p.basis.client.FindTarget(
		context.Background(),
		&vagrant_server.FindTargetRequest{
			Target: t,
		},
	)
	if err == nil && result.Found {
		target := &Target{
			ui:      p.UI(),
			project: p,
			target:  result.Target,
			logger:  p.logger.Named("target"),
		}
		p.Targets = append(p.Targets, target)

		return target, nil
	}

	p.logger.Trace("failed to locate existing target", "target", t,
		"result", result, "error", err)

	// TODO: set machine box from vagrant file

	if t.Datadir == nil {
		t.Datadir = p.GetDataDir()
	}

	// TODO: this is specialized
	// if t.Provider == "" {
	// 	t.Provider, err = p.GetDefaultProvider([]string{}, false, true)
	// }

	uresult, err := p.basis.client.UpsertTarget(
		context.Background(),
		&vagrant_server.UpsertTargetRequest{
			Target: t,
		},
	)
	if err != nil {
		return nil, err
	}

	target = &Target{
		ui:      p.UI(),
		project: p,
		target:  uresult.Target,
		logger:  p.logger.Named("target"),
	}

	p.Targets = append(p.Targets, target)

	return target, nil
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

func (p *Project) GetDataDir() *vagrant_plugin_sdk.Args_DataDir_Target {
	// TODO: probably need to get datadir from the projet + basis

	root, _ := paths.VagrantHome()
	cacheDir := root.Join("cache")
	dataDir := root.Join("data")
	tmpDir := root.Join("tmp")

	return &vagrant_plugin_sdk.Args_DataDir_Target{
		CacheDir: cacheDir.String(),
		DataDir:  dataDir.String(),
		RootDir:  root.String(),
		TempDir:  tmpDir.String(),
	}
}

func (p *Project) GetTarget(name string) (t *Target, err error) {
	for _, t = range p.Targets {
		if t.Ref().Name == name {
			return
		}
	}
	return nil, errors.New("failed to locate requested target")
}

func (p *Project) UI() terminal.UI {
	return p.ui
}

func (p *Project) Close() error {
	return p.basis.Close()
}

// Ref returns the raw Vagrant server API client.
func (p *Project) Ref() *vagrant_plugin_sdk.Ref_Project {
	return &vagrant_plugin_sdk.Ref_Project{
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
