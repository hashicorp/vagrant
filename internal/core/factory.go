// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type Scope interface {
	Close() error
	Closer(func() error)
	Init() error
	Reload() error
	ResourceId() (string, error)
	Save() error
}

type Factory struct {
	cache   cacher.Cache
	cleanup cleanup.Cleanup
	client  *serverclient.VagrantClient
	ctx     context.Context
	logger  hclog.Logger
	plugins *plugin.Manager
	ui      terminal.UI
}

func NewFactory(
	ctx context.Context,
	client *serverclient.VagrantClient,
	logger hclog.Logger,
	plugins *plugin.Manager,
	ui terminal.UI,
) *Factory {
	return &Factory{
		cache:   cacher.New(),
		ctx:     ctx,
		cleanup: cleanup.New(),
		client:  client,
		logger:  logger.Named("factory"),
		plugins: plugins,
		ui:      ui,
	}
}

func (f *Factory) Closer(fn cleanup.CleanupFn) {
	f.cleanup.Do(fn)
}

func (f *Factory) Close() error {
	f.logger.Trace("closing factory")
	return f.cleanup.Close()
}

func (f *Factory) NewBasis(resourceId string, opts ...BasisOption) (*Basis, error) {
	f.logger.Trace("factory basis load started")
	defer func() { f.logger.Trace("factory basis load completed") }()

	// If we have a name, check if it's registered and return
	// the existing basis if available
	if resourceId != "" {
		if b, ok := f.cache.Fetch(resourceId); ok {
			return b.(*Basis), nil
		}
	}

	opts = append(opts,
		WithFactory(f),
	)

	b, err := NewBasis(f.ctx, opts...)
	if err != nil {
		return nil, err
	}

	// Set any unset values which we can provide
	if b.client == nil {
		b.client = f.client
	}
	if b.logger == nil {
		b.logger = f.logger
	}
	if b.ui == nil {
		b.ui = f.ui
	}
	if b.plugins == nil {
		b.plugins = f.plugins
	}

	// Now that we have the basis information loaded, check if
	// we have a cached version and return that if so
	if existingB, ok := f.cache.Fetch(b.basis.ResourceId); ok {
		f.logger.Debug("found existing basis in cache, closing new instance")
		if err := b.Close(); err != nil {
			return nil, err
		}

		return existingB.(*Basis), nil
	}

	// Initialize the basis to complete setup
	if err = b.Init(); err != nil {
		b.logger.Error("failed to initialize basis",
			"error", err,
		)
		b.Close()

		return nil, err
	}

	// Now that basis is fully setup, add it to the cache
	f.cache.Register(b.basis.ResourceId, b)

	// Remove the basis from the cache when closed
	b.Closer(func() error {
		f.cache.Delete(b.basis.ResourceId)
		return nil
	})

	// When the factory is closed, ensure this basis is closed
	f.Closer(func() (err error) {
		return b.Close()
	})

	return b, nil
}

func (f *Factory) NewProject(popts ...ProjectOption) (*Project, error) {
	f.logger.Trace("factory project load started")
	defer func() { f.logger.Trace("factory project load completed") }()

	// Get a new project instance
	p, err := NewProject(popts...)
	if err != nil {
		return nil, err
	}

	// Attach our logger
	p.logger = f.logger

	// Set the client directly so we can attempt to reload
	if p.client == nil {
		p.client = f.client
	}

	// Set the factory so we can load basis if required
	if p.factory == nil {
		p.factory = f
	}

	// If the resource id isn't set, attempt a reload. We
	// don't care if it fails, at this point. If it is
	// successful, it will allow us to properly check
	// the cache
	if p.project.ResourceId == "" {
		_ = p.Reload()
	}

	// Check if we already have an instance loaded
	if p.project.ResourceId != "" {
		if project, ok := f.cache.Fetch(p.project.ResourceId); ok {
			f.logger.Debug("found existing project in cache, closing new instance")
			if err = p.Close(); err != nil {
				return nil, err
			}
			return project.(*Project), nil
		}
	}

	// Initialize the project so it is ready for use
	if err = p.Init(); err != nil {
		return nil, err
	}

	// Close the project when the basis is closed
	p.basis.Closer(func() error {
		return p.Close()
	})

	// Cache the project
	f.cache.Register(p.project.ResourceId, p)

	// Remove the project from the cache when closed
	p.Closer(func() error {
		f.cache.Delete(p.project.ResourceId)
		return nil
	})

	return p, nil
}

func (f *Factory) NewTarget(topts ...TargetOption) (*Target, error) {
	f.logger.Trace("factory target load started")
	defer func() { f.logger.Trace("factory target load completed") }()

	// Get a new target instance
	t, err := NewTarget(topts...)
	if err != nil {
		return nil, err
	}

	// Attach our logger
	t.logger = f.logger

	// Set the client directly so we can attempt to reload
	if t.client == nil {
		t.client = f.client
	}

	// Set the client directly so we can attempt to reload
	if t.factory == nil {
		t.factory = f
	}

	// If the resource id isn't set, attempt a reload. We
	// don't care if it fails, at this point. If it is
	// successful, it will allow us to properly check
	// the cache
	if t.target.ResourceId == "" {
		_ = t.Reload()
	}

	// Check if we already have an instance loaded
	if t.target.ResourceId != "" {
		if target, ok := f.cache.Fetch(t.target.ResourceId); ok {
			f.logger.Debug("found existing target in cache, closing new instance")
			if err = t.Close(); err != nil {
				return nil, err
			}
			return target.(*Target), nil
		}
	}

	// If we have no project set, load the project
	if t.project == nil && t.target.Project != nil {
		t.project, err = f.NewProject(
			WithProjectRef(t.target.Project),
		)
		if err != nil {
			return nil, err
		}
	}

	// Initialize the target so it is ready for use
	if err = t.Init(); err != nil {
		return nil, err
	}

	// Close the target when the project is closed
	t.project.Closer(func() error {
		return t.Close()
	})

	// Cache the target
	f.cache.Register(t.target.ResourceId, t)

	// Remove the target from the cache when closed
	t.Closer(func() error {
		f.cache.Delete(t.target.ResourceId)
		return nil
	})

	return t, nil
}
