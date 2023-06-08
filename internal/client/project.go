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

	vp, err := LoadVagrantfile(
		p.vagrantfile, l, raw.(serverclient.RubyVagrantClient))

	if err != nil {
		return err
	}

	p.project.Configuration = vp
	p.project.Basis = p.basis.Ref()
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
	if result != nil {
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

	// TODO(spox): Some adjustment is needed on how targets
	//             should be loaded here when their origin
	//             will be the vagrantfile
	return nil, fmt.Errorf("cannot load target")
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
