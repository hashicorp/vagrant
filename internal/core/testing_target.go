// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package core

import (
	"fmt"
	"path/filepath"

	"github.com/imdario/mergo"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
)

// TestTarget returns a fully in-memory and side-effect free Target that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestTarget(t testing.T, p *Project, st *vagrant_server.Target, opts ...TestTargetOption) (target *Target) {
	if st.Name == "" {
		st.Name = filepath.Base(testTempDir(t))
	}

	target, err := p.factory.NewTarget(
		[]TargetOption{
			WithTargetRef(
				&vagrant_plugin_sdk.Ref_Target{
					Project:    p.Ref().(*vagrant_plugin_sdk.Ref_Project),
					Name:       st.Name,
					ResourceId: st.ResourceId,
				},
			),
		}...,
	)
	require.NoError(t, err)
	require.NoError(t, mergo.Merge(target.target, st))

	for _, opt := range opts {
		if oerr := opt(target); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}
	require.NoError(t, err)
	require.NoError(t, target.Save())
	require.NoError(t, p.Reload())

	return
}

// TestMinimalTarget uses a minimal project to setup the most basic target
// that will work for testing
func TestMinimalTarget(t testing.T) (target *Target) {
	tp := TestMinimalProject(t)
	target, err := tp.factory.NewTarget(
		[]TargetOption{
			WithProject(tp),
			WithTargetRef(
				&vagrant_plugin_sdk.Ref_Target{
					Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
					Name:    filepath.Base(testTempDir(t)),
				},
			),
		}...,
	)
	require.NoError(t, err)
	require.NoError(t, target.Save())
	require.NoError(t, tp.Reload())

	return
}

// TestMachine returns a fully in-memory and side-effect free Machine that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestMachine(t testing.T, tp *Project, opts ...TestTargetOption) (machine *Machine) {
	tt := TestTarget(t, tp, &vagrant_server.Target{})
	specialized, err := tt.Specialize((*core.Machine)(nil))
	require.NoError(t, err)

	machine = specialized.(*Machine)
	for _, opt := range opts {
		if oerr := opt(machine); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}
	require.NoError(t, err)

	return
}

// TestMinimalMachine uses a minimal project to setup the most basic machine
// that will work for testing
func TestMinimalMachine(t testing.T) (machine *Machine) {
	tp := TestMinimalProject(t)
	tt := TestTarget(t, tp, &vagrant_server.Target{})
	specialized, err := tt.Specialize((*core.Machine)(nil))
	require.NoError(t, err)

	machine = specialized.(*Machine)
	return
}

type TestTargetOption func(interface{}) error

func WithTestTargetConfig(config *component.ConfigData) TestTargetOption {
	return func(raw interface{}) (err error) {
		switch v := raw.(type) {
		case *Target:
			return mergo.Merge(v.vagrantfile.root, config)
		case *Machine:
			return mergo.Merge(v.vagrantfile.root, config)
		default:
			panic(fmt.Sprintf("Invalid type for TestTargetOption (%T)", raw))
		}
	}
}

func WithTestTargetProvider(provider string) TestTargetOption {
	return func(raw interface{}) (err error) {
		switch v := raw.(type) {
		case *Target:
			v.target.Provider = provider
		case *Machine:
			v.target.Provider = provider
		default:
			panic(fmt.Sprintf("Invalid type for TestTargetOption (%T)", raw))
		}
		return
	}
}
