// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

import (
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
)

// TestConfig returns a Config from a string source and fails the test if
// parsing the configuration fails.
func TestConfig(t testing.T, src string) *Config {
	t.Helper()

	// Write our test config to a temp location
	td, err := ioutil.TempDir("", "vagrant")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	path := filepath.Join(td, "vagrant.hcl")
	require.NoError(t, ioutil.WriteFile(path, []byte(src), 0644))

	result, err := Load(path, "")
	require.NoError(t, err)

	return result
}

// TestSource returns valid configuration.
func TestSource(t testing.T) string {
	return testSourceVal
}

// TestConfigFile writes the default Vagrant configuration file with
// the given contents.
func TestConfigFile(t testing.T, src string) {
	require.NoError(t, ioutil.WriteFile(Filename, []byte(src), 0644))
}

const testSourceVal = ``
