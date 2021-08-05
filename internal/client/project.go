package client

import (
	"context"
	"fmt"
	"os"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	vagrant_plugin_sdk "github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// Project is the primary structure for interacting with a Vagrant
// server as a client. The client exposes a slightly higher level of
// abstraction over the server API for performing operations locally and
// remotely.
type Project struct {
	basis       *Basis
	client      *Client
	ctx         context.Context
	logger      hclog.Logger
	path        path.Path
	project     *vagrant_server.Project
	ui          terminal.UI
	vagrant     *serverclient.VagrantClient
	vagrantfile path.Path
}

// Finds the Vagrantfile associated with the project
func (p *Project) LoadVagrantfile() error {
	l := p.logger.With(
		"basis", p.basis.basis.Name,
		"project", p.project.Name,
		"path", p.vagrantfile,
	)
	l.Trace("attempting to load project vagrantfile")
	if p.vagrantfile == nil {
		l.Warn("project vagrantfile has not been set")
		return nil
	}

	// If the path does not exist, no Vagrantfile was found
	if _, err := os.Stat(p.vagrantfile.String()); os.IsNotExist(err) {
		l.Warn("project vagrantfile does not exist")
		return nil
	}

	raw, err := p.client.rubyRuntime.Dispense("vagrantrubyruntime")
	if err != nil {
		l.Warn("failed to load ruby runtime for vagrantfile parsing",
			"error", err,
		)

		return err
	}
	rvc, ok := raw.(serverclient.RubyVagrantClient)
	if !ok {
		l.Warn("failed to attach to ruby runtime for vagrantfile parsing")

		return fmt.Errorf("Couldn't attach to Ruby runtime")
	}

	vagrantfile, err := rvc.ParseVagrantfile(p.vagrantfile.String())
	if err != nil {
		l.Error("failed to parse project vagrantfile",
			"error", err,
		)

		return err
	}

	l.Trace("storaing updated project configuration",
		"configuration", vagrantfile,
	)

	p.project.Configuration = vagrantfile
	// Push Vagrantfile updates to project
	result, err := p.vagrant.UpsertProject(
		p.ctx,
		&vagrant_server.UpsertProjectRequest{
			Project: p.project,
		},
	)

	if err != nil {
		l.Error("failed to store project updates",
			"error", err,
		)

		return err
	}
	p.project = result.Project

	return nil
}

func (p *Project) LoadTarget(n string) (*Target, error) {
	result, err := p.vagrant.FindTarget(
		p.ctx,
		&vagrant_server.FindTargetRequest{
			Target: &vagrant_server.Target{
				Name:    n,
				Project: p.Ref(),
			},
		},
	)
	if err != nil {
		return nil, err
	}

	// If the target exists, load and return
	if result.Found {
		return &Target{
			client:  p.client,
			ctx:     p.ctx,
			logger:  p.logger.Named("target"),
			project: p,
			target:  result.Target,
			ui:      p.ui,
			vagrant: p.vagrant,
		}, nil
	}

	// Doesn't exist so lets create it
	// TODO(spox): do we actually want to create these?

	uresult, err := p.vagrant.UpsertTarget(p.ctx,
		&vagrant_server.UpsertTargetRequest{
			Target: &vagrant_server.Target{
				Name:    n,
				Project: p.Ref(),
			},
		},
	)
	if err != nil {
		return nil, err
	}

	return &Target{
		client:  p.client,
		ctx:     p.ctx,
		logger:  p.logger.Named("project"),
		target:  uresult.Target,
		ui:      p.ui,
		vagrant: p.vagrant,
	}, nil
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
