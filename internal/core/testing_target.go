package core

import (
	"context"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/mitchellh/go-testing-interface"
)

// TestTarget returns a fully in-memory and side-effect free Target that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestTarget(t testing.T, opts ...TargetOption) (target *Target, err error) {
	tp := TestProject(t)
	tp.basis.client.UpsertTarget(
		context.Background(),
		&vagrant_server.UpsertTargetRequest{
			Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
			Target: &vagrant_server.Target{
				Name:    "test-target",
				Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
			},
		},
	)
	target, err = tp.LoadTarget([]TargetOption{
		WithTargetRef(&vagrant_plugin_sdk.Ref_Target{Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project), Name: "test-target"}),
	}...)

	for _, opt := range opts {
		if oerr := opt(target); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}

	return
}

// TestMachine returns a fully in-memory and side-effect free Machine that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestMachine(t testing.T, opts ...TestMachineOption) (machine *Machine, err error) {
	tt, _ := TestTarget(t)
	specialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		return nil, err
	}
	machine = specialized.(*Machine)
	for _, opt := range opts {
		if oerr := opt(machine); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}
	return
}

type TestMachineOption func(*Machine) error

func WithTestTargetConfig(config *vagrant_plugin_sdk.Vagrantfile_MachineConfig) TestMachineOption {
	return func(m *Machine) (err error) {
		m.target.Configuration = config
		return
	}
}
