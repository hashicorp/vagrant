package client

import (
	"context"
	"fmt"
	"io"
	"os"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	configpkg "github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type Basis struct {
	basis        *vagrant_server.Basis
	cleanupFuncs []func() error
	client       *Client
	ctx          context.Context
	logger       hclog.Logger
	path         path.Path
	ui           terminal.UI
	vagrant      *serverclient.VagrantClient
}

func (b *Basis) DetectProject() (p *Project, err error) {
	// look for a vagrantfile!
	v, err := configpkg.FindPath(nil, "")
	// if an error was encountered, or no path was found, we return
	if err != nil || v == nil {
		return
	}

	// we did find a path, so use the directory name as project name
	// TODO(spox): we'll need to do better than just dir name
	_, n := v.Dir().Base().Split()
	p, err = b.LoadProject(n)
	if err != nil && status.Code(err) != codes.NotFound {
		return
	}

	if err == nil {
		p.vagrantfile = v
		return
	}

	result, err := b.vagrant.UpsertProject(
		b.ctx,
		&vagrant_server.UpsertProjectRequest{
			Project: &vagrant_server.Project{
				Name:  n,
				Basis: b.Ref(),
				Path:  v.Dir().String(),
			},
		},
	)
	if err != nil {
		return
	}

	return &Project{
		basis:       b,
		client:      b.client,
		ctx:         b.ctx,
		logger:      b.logger.Named("project"),
		project:     result.Project,
		ui:          b.ui,
		vagrant:     b.vagrant,
		vagrantfile: v,
	}, nil
}

func (b *Basis) LoadProject(n string) (*Project, error) {
	result, err := b.vagrant.FindProject(
		b.ctx,
		&vagrant_server.FindProjectRequest{
			Project: &vagrant_server.Project{
				Name:  n,
				Basis: b.Ref(),
			},
		},
	)
	if err != nil {
		return nil, err
	}

	if !result.Found {
		return nil, NotFoundErr
	}

	return &Project{
		basis:   b,
		client:  b.client,
		ctx:     b.ctx,
		logger:  b.logger.Named("project"),
		project: result.Project,
		ui:      b.ui,
		vagrant: b.vagrant,
	}, nil
}

// Finds the Vagrantfile associated with the basis
func (b *Basis) LoadVagrantfile() error {
	vpath := b.path.Join(configpkg.GetVagrantfileName())
	l := b.logger.With(
		"basis", b.basis.Name,
		"path", vpath,
	)

	l.Trace("attempting to load basis vagrantfile")

	// If the path does not exist, no Vagrantfile was found
	if _, err := os.Stat(vpath.String()); os.IsNotExist(err) {
		l.Warn("basis vagrantfile does not exist")

		return nil
	} else if err != nil {
		l.Error("failed to load basis vagrantfile",
			"error", err,
		)

		return err
	}

	raw, err := b.client.rubyRuntime.Dispense("vagrantrubyruntime")
	if err != nil {
		l.Warn("failed to load ruby runtime for vagrantfile parsing",
			"error", err,
		)

		return err
	}
	rvc, ok := raw.(serverclient.RubyVagrantClient)
	if !ok {
		l.Warn("failed to attach to ruby runtime for vagrantfile parsing",
			"error", err,
		)

		return fmt.Errorf("Couldn't attach to Ruby runtime")
	}

	vagrantfile, err := rvc.ParseVagrantfile(vpath.String())
	if err != nil {
		l.Error("failed to parse basis vagrantfile",
			"error", err,
		)

		return err
	}

	l.Trace("storing updated basis configuration",
		"configuration", vagrantfile,
	)

	b.basis.Configuration = vagrantfile
	// Push Vagrantfile updates to basis
	result, err := b.vagrant.UpsertBasis(
		b.ctx,
		&vagrant_server.UpsertBasisRequest{
			Basis: b.basis,
		},
	)

	if err != nil {
		l.Error("failed to store basis updates",
			"error", err,
		)

		return err
	}

	b.basis = result.Basis
	return nil
}

func (b *Basis) Ref() *vagrant_plugin_sdk.Ref_Basis {
	return &vagrant_plugin_sdk.Ref_Basis{
		Name:       b.basis.Name,
		ResourceId: b.basis.ResourceId,
	}
}

func (b *Basis) Close() error {
	for _, f := range b.cleanupFuncs {
		f()
	}

	if closer, ok := b.ui.(io.Closer); ok {
		closer.Close()
	}
	return nil
}

// Client returns the raw Vagrant server API client.
func (b *Basis) Client() *serverclient.VagrantClient {
	return b.vagrant
}

func (b *Basis) VagrantRubyRuntime() plugin.ClientProtocol {
	return b.client.rubyRuntime
}

func (b *Basis) UI() terminal.UI {
	return b.ui
}
