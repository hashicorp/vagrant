package core

import (
	"context"
	"sync"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type Factory struct {
	ctx        context.Context
	cleanup    cleanup.Cleanup
	client     *serverclient.VagrantClient
	logger     hclog.Logger
	m          sync.Mutex
	plugins    *plugin.Manager
	registered map[string]*Basis
	ui         terminal.UI
}

func NewFactory(
	ctx context.Context,
	client *serverclient.VagrantClient,
	logger hclog.Logger,
	plugins *plugin.Manager,
	ui terminal.UI,
) *Factory {
	return &Factory{
		ctx:        ctx,
		cleanup:    cleanup.New(),
		client:     client,
		logger:     logger,
		plugins:    plugins,
		ui:         ui,
		registered: map[string]*Basis{},
	}
}

func (f *Factory) Closer(fn cleanup.CleanupFn) {
	f.cleanup.Do(fn)
}

func (f *Factory) Close() error {
	return f.cleanup.Close()
}

func (f *Factory) New(name string, opts ...BasisOption) (*Basis, error) {
	f.m.Lock()
	defer f.m.Unlock()

	// If we have a name, check if it's registered and return
	// the existing basis if available
	if name != "" {
		if b, ok := f.registered[name]; ok {
			return b, nil
		}
	}

	// Create a child plugin manager for the basis
	// which we will close when the basis is closed
	pm := f.plugins.Sub(name)

	// Update the options to include this factory and
	// our settings when creating the new basis
	opts = append(opts,
		WithFactory(f),
		FromBasis(
			&Basis{
				ctx:     f.ctx,
				client:  f.client,
				logger:  f.logger,
				plugins: pm,
				ui:      f.ui,
			},
		),
	)

	b, err := NewBasis(f.ctx, opts...)
	if err != nil {
		return nil, err
	}

	// Now there's a chance we already have this basis
	// registered if the name was not provided for
	// an initial lookup. If it is registered, close
	// this new basis, discard, and return the
	// registered one
	if existingB, ok := f.registered[b.Name()]; ok {
		f.logger.Info("there was an existing basis so closing the new one",
			"name", name,
			"basis-name", b.Name(),
		)
		b.Close()
		return existingB, nil
	}

	f.registered[b.Name()] = b
	// Remove the basis from the registered list when closed
	b.Closer(func() error {
		f.m.Lock()
		defer f.m.Unlock()
		delete(f.registered, b.Name())
		return nil
	})

	// Close the child plugin manager
	b.Closer(func() error {
		return pm.Close()
	})

	// Ensure any registered basis is closed
	// when the factory is closed
	f.Closer(func() (err error) {
		for _, b := range f.registered {
			berr := b.Close()
			if berr != nil {
				err = multierror.Append(err, berr)
			}
		}
		return
	})

	return b, nil
}
