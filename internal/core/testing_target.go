package core

import (
	"context"

	"github.com/imdario/mergo"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/server/ptypes"
	"github.com/mitchellh/go-testing-interface"
)

// TestTarget returns a fully in-memory and side-effect free Target that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestTarget(t testing.T, p *Project, st *vagrant_server.Target) (target *Target) {
	testingTarget := ptypes.TestTarget(t, st)
	testingTarget.Project = p.Ref().(*vagrant_plugin_sdk.Ref_Project)
	_, err := p.basis.client.UpsertTarget(
		context.Background(),
		&vagrant_server.UpsertTargetRequest{
			Project: p.Ref().(*vagrant_plugin_sdk.Ref_Project),
			Target:  testingTarget,
		},
	)
	if err != nil {
		t.Fatal(err)
	}

	target, err = p.LoadTarget([]TargetOption{
		WithTargetRef(
			&vagrant_plugin_sdk.Ref_Target{
				Project: p.Ref().(*vagrant_plugin_sdk.Ref_Project),
				Name:    testingTarget.Name,
			},
		),
	}...)
	if err != nil {
		t.Fatal(err)
	}

	if err = p.refreshProject(); err != nil {
		t.Fatal(err)
	}

	return
}

// TestMinimalTarget uses a minimal project to setup the most basic target
// that will work for testing
func TestMinimalTarget(t testing.T) (target *Target) {
	tp := TestMinimalProject(t)
	_, err := tp.basis.client.UpsertTarget(
		context.Background(),
		&vagrant_server.UpsertTargetRequest{
			Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
			Target: &vagrant_server.Target{
				Name:    "test-target",
				Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
			},
		},
	)
	if err != nil {
		t.Fatal(err)
	}

	target, err = tp.LoadTarget([]TargetOption{
		WithTargetRef(
			&vagrant_plugin_sdk.Ref_Target{
				Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
				Name:    "test-target",
			},
		),
	}...)
	if err != nil {
		t.Fatal(err)
	}

	return
}

// TestMachine returns a fully in-memory and side-effect free Machine that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestMachine(t testing.T, tp *Project, opts ...TestMachineOption) (machine *Machine) {
	tt := TestTarget(t, tp, &vagrant_server.Target{})
	specialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Fatal(err)
	}

	machine = specialized.(*Machine)
	for _, opt := range opts {
		if oerr := opt(machine); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}
	if err != nil {
		t.Fatal(err)
	}

	return
}

// TestMinimalMachine uses a minimal project to setup the most basic machine
// that will work for testing
func TestMinimalMachine(t testing.T) (machine *Machine) {
	tp := TestMinimalProject(t)
	tt := TestTarget(t, tp, &vagrant_server.Target{})
	specialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Fatal(err)
	}
	machine = specialized.(*Machine)
	return
}

type TestMachineOption func(*Machine) error

func WithTestTargetConfig(config *component.ConfigData) TestMachineOption {
	return func(m *Machine) (err error) {
		return mergo.Merge(m.vagrantfile.root, config)
	}
}

func WithTestTargetProvider(provider string) TestMachineOption {
	return func(m *Machine) (err error) {
		m.target.Provider = provider
		return
	}
}
