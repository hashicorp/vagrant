// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package core

import (
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
)

// TestProject returns a fully in-memory and side-effect free Project that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestProject(t testing.T, opts ...BasisOption) *Project {
	path := testTempDir(t)
	name := filepath.Base(path)

	b := TestBasis(t, opts...)
	p, err := b.factory.NewProject(
		[]ProjectOption{
			WithBasis(b),
			WithProjectRef(
				&vagrant_plugin_sdk.Ref_Project{
					Basis: b.Ref().(*vagrant_plugin_sdk.Ref_Basis),
					Name:  name,
					Path:  path,
				},
			),
		}...,
	)

	require.NoError(t, err)
	require.NoError(t, p.Save())

	return p
}

// TestMinimalProject uses a minimal basis to setup the most basic project
// that will work for testing
func TestMinimalProject(t testing.T) *Project {
	path := testTempDir(t)
	name := filepath.Base(path)

	pluginManager := plugin.TestManager(t)
	b := TestBasis(t, WithPluginManager(pluginManager))
	p, err := b.factory.NewProject(
		[]ProjectOption{
			WithBasis(b),
			WithProjectRef(
				&vagrant_plugin_sdk.Ref_Project{
					Basis: b.Ref().(*vagrant_plugin_sdk.Ref_Basis),
					Name:  name,
					Path:  path,
				},
			),
		}...,
	)

	require.NotEmpty(t, p.project.Path)

	require.NoError(t, err)
	require.NoError(t, p.Save())

	return p
}

func testTempDir(t testing.T) string {
	t.Helper()

	dir, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}
