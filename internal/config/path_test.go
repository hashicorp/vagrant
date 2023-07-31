// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/stretchr/testify/require"
)

func TestFindPath(t *testing.T) {
	t.Run("uses dir and filename args if passed and file exists", func(t *testing.T) {
		require := require.New(t)

		dir, err := ioutil.TempDir("", "test")
		require.NoError(err)
		defer os.RemoveAll(dir)

		p := filepath.Join(dir, "MyCoolFile")
		file, err := os.Create(p)
		require.NoError(err)
		file.Close()

		out, err := FindPath(path.NewPath(dir), "MyCoolFile")
		require.NoError(err)
		require.Equal(p, out.String())
	})

	t.Run("when VAGRANT_CWD is not set", func(t *testing.T) {
		oldVcwd, ok := os.LookupEnv("VAGRANT_CWD")
		if ok {
			os.Unsetenv("VAGRANT_CWD")
			defer os.Setenv("VAGRANT_CWD", oldVcwd)
		}

		t.Run("uses cwd and Vagrantfile when blank args passed", func(t *testing.T) {
			require := require.New(t)

			dir, err := ioutil.TempDir("", "test")
			require.NoError(err)
			defer os.RemoveAll(dir)

			p := filepath.Join(dir, "Vagrantfile")
			file, err := os.Create(p)
			require.NoError(err)
			file.Close()

			oldCwd, err := os.Getwd()
			require.NoError(err)
			os.Chdir(dir)
			defer os.Chdir(oldCwd)

			out, err := FindPath(nil, "")
			require.NoError(err)

			// On mac, tempfiles land in a place that can be referenced as either
			// /tmp/ or /private/tmp/ (the former is a symlink to the latter).
			// This can mess with path equality assertions. We explicitly
			// eval symlinks on both expected and actual here to flush out that
			// discrepancy.
			absolutePath, err := filepath.EvalSymlinks(p)
			require.NoError(err)

			absoluteOut, err := out.EvalSymLinks()
			require.NoError(err)

			require.Equal(absolutePath, absoluteOut.String())
		})

		t.Run("walks parent dirs looking for Vagrantfile", func(t *testing.T) {
			require := require.New(t)

			dir, err := ioutil.TempDir("", "test")
			require.NoError(err)
			defer os.RemoveAll(dir)

			deepPath := path.NewPath(filepath.Join(dir, "a", "b"))
			err = os.MkdirAll(deepPath.String(), 0700)
			require.NoError(err)

			notDeepFile := filepath.Join(dir, "Vagrantfile")
			file, err := os.Create(notDeepFile)
			require.NoError(err)
			file.Close()

			out, err := FindPath(deepPath, "")
			require.NoError(err)
			require.Equal(notDeepFile, out.String())
		})

		t.Run("returns nil if parent walk comes up empty", func(t *testing.T) {
			require := require.New(t)

			dir, err := ioutil.TempDir("", "test")
			require.NoError(err)
			defer os.RemoveAll(dir)

			deepPath := path.NewPath(filepath.Join(dir, "a", "b"))
			err = os.MkdirAll(deepPath.String(), 0700)
			require.NoError(err)

			out, err := FindPath(deepPath, "")
			require.NoError(err)
			require.Nil(out)
		})
	})

	t.Run("honors VAGRANT_CWD if set and exists", func(t *testing.T) {
		require := require.New(t)

		dir, err := ioutil.TempDir("", "test")
		require.NoError(err)
		defer os.RemoveAll(dir)

		os.Setenv("VAGRANT_CWD", dir)
		defer os.Unsetenv("VAGRANT_CWD")

		file, err := os.Create(filepath.Join(dir, "Vagrantfile"))
		require.NoError(err)
		file.Close()

		out, err := FindPath(nil, "")
		require.NoError(err)
		require.Equal(filepath.Join(dir, "Vagrantfile"), out.String())
	})

	t.Run("errors if VAGRANT_CWD is set and does not exist", func(t *testing.T) {
		require := require.New(t)

		os.Setenv("VAGRANT_CWD", filepath.Join(os.TempDir(), "idontexit"))
		defer os.Unsetenv("VAGRANT_CWD")

		_, err := FindPath(nil, "")
		require.Error(err)
		require.Contains(err.Error(), "does not exist")
	})
}
