// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package runner

import (
	"context"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"

	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	configpkg "github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/core"
	vagrantplugin "github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// TestRunner returns an initialized runner pointing to an in-memory test
// server. This will close automatically on test completion.
//
// This will also change the working directory to a temporary directory
// so that any side effect file creation doesn't impact the real working
// directory. If you need to use your working directory, query it before
// calling this.
func TestRunner(t testing.T, opts ...Option) *Runner {
	require := require.New(t)
	client := singleprocess.TestServer(t)
	rubyRunTime, err := TestRunnerVagrantRubyRuntime(t)

	// Initialize our runner
	runner, err := New(append([]Option{
		WithClient(client),
		WithVagrantRubyRuntime(rubyRunTime),
	}, opts...)...)
	require.NoError(err)
	t.Cleanup(func() { runner.Close() })

	// Move into a temporary directory
	td := testTempDir(t)
	testChdir(t, td)

	// Create a valid vagrant configuration file
	configpkg.TestConfigFile(t, configpkg.TestSource(t))

	return runner
}

func TestRunnerVagrantRubyRuntime(t testing.T) (rubyRuntime plugin.ClientProtocol, err error) {
	// TODO: Update for actual release usage. This is dev only now.
	// TODO: We should also locate a free port on startup and use that port
	_, this_dir, _, _ := runtime.Caller(0)
	cmd := exec.Command(
		"bundle", "exec", "vagrant", "serve",
	)
	cmd.Env = []string{
		"BUNDLE_GEMFILE=" + filepath.Join(this_dir, "../../..", "Gemfile"),
		"VAGRANT_I_KNOW_WHAT_IM_DOING_PLEASE_BE_QUIET=true",
		"VAGRANT_LOG=debug",
		"VAGRANT_LOG_FILE=/tmp/vagrant.log",
	}

	config := serverclient.RubyVagrantPluginConfig(hclog.New(&hclog.LoggerOptions{Level: hclog.Trace}))
	config.Cmd = cmd
	c := plugin.NewClient(config)
	if _, err = c.Start(); err != nil {
		return
	}
	rubyRuntime, err = c.Client()
	t.Cleanup(func() { c.Kill() })
	return
}

func testChdir(t testing.T, dir string) {
	pwd, err := os.Getwd()
	require.NoError(t, err)
	require.NoError(t, os.Chdir(dir))
	t.Cleanup(func() { require.NoError(t, os.Chdir(pwd)) })
}

func testTempDir(t testing.T) string {
	dir, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}

func TestBasis(t testing.T, opts ...core.BasisOption) (b *vagrant_plugin_sdk.Ref_Basis) {
	td, err := ioutil.TempDir("", "core")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	projDir, err := datadir.NewBasis(td)
	require.NoError(t, err)

	defaultOpts := []core.BasisOption{
		core.WithBasisDataDir(projDir),
		core.WithBasisRef(&vagrant_plugin_sdk.Ref_Basis{Name: "TESTBAS"}),
	}
	pluginManager := vagrantplugin.NewManager(
		context.Background(),
		nil,
		hclog.New(&hclog.LoggerOptions{}),
	)
	opts = append(opts, core.WithPluginManager(pluginManager))

	basis, err := core.NewBasis(context.Background(), append(opts, defaultOpts...)...)
	require.NoError(t, err)
	b = basis.Ref().(*vagrant_plugin_sdk.Ref_Basis)
	t.Cleanup(func() { basis.Close() })
	return
}
