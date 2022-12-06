package core

import (
	"github.com/mitchellh/go-testing-interface"

	//	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
)

// TestProject returns a fully in-memory and side-effect free Project that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestProject(t testing.T, opts ...BasisOption) *Project {
	b := TestBasis(t, opts...)
	p, err := b.factory.NewProject(
		[]ProjectOption{
			WithBasis(b),
			WithProjectName("test-project"),
		}...,
	)

	if err != nil {
		t.Fatal(err)
	}

	return p
}

// TestMinimalProject uses a minimal basis to setup the most basic project
// that will work for testing
func TestMinimalProject(t testing.T) *Project {
	pluginManager := plugin.TestManager(t)
	b := TestBasis(t, WithPluginManager(pluginManager))
	p, err := b.factory.NewProject(
		[]ProjectOption{
			WithBasis(b),
			WithProjectName("test-project"),
		}...,
	)

	if err != nil {
		t.Fatal(err)
	}

	return p
}
