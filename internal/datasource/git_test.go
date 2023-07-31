// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package datasource

import (
	"context"
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/hashicorp/go-hclog"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var testHasGit bool

func init() {
	if _, err := exec.LookPath("git"); err == nil {
		testHasGit = true
	}
}

func TestGitSourceOverride(t *testing.T) {
	cases := []struct {
		Name     string
		Input    *vagrant_server.Job_DataSource
		M        map[string]string
		Expected *vagrant_server.Job_DataSource
		Error    string
	}{
		{
			"nothing",
			&vagrant_server.Job_DataSource{
				Source: &vagrant_server.Job_DataSource_Git{
					Git: &vagrant_server.Job_Git{
						Url: "foo",
					},
				},
			},
			nil,
			&vagrant_server.Job_DataSource{
				Source: &vagrant_server.Job_DataSource_Git{
					Git: &vagrant_server.Job_Git{
						Url: "foo",
					},
				},
			},
			"",
		},

		{
			"ref",
			&vagrant_server.Job_DataSource{
				Source: &vagrant_server.Job_DataSource_Git{
					Git: &vagrant_server.Job_Git{
						Url: "foo",
					},
				},
			},
			map[string]string{"ref": "bar"},
			&vagrant_server.Job_DataSource{
				Source: &vagrant_server.Job_DataSource_Git{
					Git: &vagrant_server.Job_Git{
						Url: "foo",
						Ref: "bar",
					},
				},
			},
			"",
		},

		{
			"invalid",
			&vagrant_server.Job_DataSource{
				Source: &vagrant_server.Job_DataSource_Git{
					Git: &vagrant_server.Job_Git{
						Url: "foo",
					},
				},
			},
			map[string]string{"other": "bar"},
			nil,
			"other",
		},
	}

	for _, tt := range cases {
		t.Run(tt.Name, func(t *testing.T) {
			require := require.New(t)

			var s GitSource
			err := s.Override(tt.Input, tt.M)
			if tt.Error != "" {
				require.Error(err)
				require.Contains(err.Error(), tt.Error)
				return
			}

			require.NoError(err)
			require.Equal(tt.Expected, tt.Input)
		})
	}
}

func TestGitSourceGet(t *testing.T) {
	if !testHasGit {
		t.Skip("git not installed")
		return
	}

	require := require.New(t)

	var s GitSource
	dir, closer, err := s.Get(
		context.Background(),
		hclog.L(),
		terminal.ConsoleUI(context.Background()),
		&vagrant_server.Job_DataSource{
			Source: &vagrant_server.Job_DataSource_Git{
				Git: &vagrant_server.Job_Git{
					Url: testGitFixture(t, "git-noop"),
				},
			},
		},
		"",
	)
	require.NoError(err)
	if closer != nil {
		defer closer()
	}

	// Verify files
	_, err = os.Stat(filepath.Join(dir, "vagrant.hcl"))
	require.NoError(err)
}

// testGitFixture MUST be called before TestRunner since TestRunner
// changes our working directory.
func testGitFixture(t *testing.T, n string) string {
	t.Helper()

	// Get our full path
	wd, err := os.Getwd()
	require.NoError(t, err)
	wd, err = filepath.Abs(wd)
	require.NoError(t, err)
	path := filepath.Join(wd, "testdata", n)

	// Look for a DOTgit
	original := filepath.Join(path, "DOTgit")
	_, err = os.Stat(original)
	require.NoError(t, err)

	// Rename it
	newPath := filepath.Join(path, ".git")
	require.NoError(t, os.Rename(original, newPath))
	t.Cleanup(func() { os.Rename(newPath, original) })

	return path
}
