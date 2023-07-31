// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package funcs

import (
	"os"
	"os/exec"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
	"github.com/zclconf/go-cty/cty"
)

var testHasGit bool

func init() {
	if _, err := exec.LookPath("git"); err == nil {
		testHasGit = true
	}
}

func TestVCSGit(t *testing.T) {
	if !testHasGit {
		t.Skip("git not installed")
		return
	}

	cases := []struct {
		Name     string
		Fixture  string
		Subdir   string
		Func     func(*VCSGit, []cty.Value, cty.Type) (cty.Value, error)
		Args     []cty.Value
		Expected cty.Value
		Error    string
	}{
		{
			"hash: HEAD commit",
			"git-commits",
			"",
			(*VCSGit).refHashFunc,
			nil,
			cty.StringVal("380afd697abe993b89bfa08d8dd8724d6a513ba1"),
			"",
		},

		{
			"tag",
			"git-tag",
			"",
			(*VCSGit).refTagFunc,
			nil,
			cty.StringVal("hello"),
			"",
		},

		{
			"tag no tags",
			"git-commits",
			"",
			(*VCSGit).refTagFunc,
			nil,
			cty.StringVal(""),
			"",
		},

		{
			"remote doesn't exist",
			"git-commits",
			"",
			(*VCSGit).remoteUrlFunc,
			[]cty.Value{cty.StringVal("origin")},
			cty.UnknownVal(cty.String),
			"",
		},

		{
			"remote exists",
			"git-remote",
			"",
			(*VCSGit).remoteUrlFunc,
			[]cty.Value{cty.StringVal("origin")},
			cty.StringVal("https://github.com/hashicorp/example.git"),
			"",
		},
	}

	for _, tt := range cases {
		t.Run(tt.Name, func(t *testing.T) {
			require := require.New(t)

			path := filepath.Join("testdata", tt.Fixture)
			testGitFixture(t, path)
			if tt.Subdir != "" {
				path = filepath.Join(path, tt.Subdir)
			}

			s := &VCSGit{Path: path}
			result, err := tt.Func(s, tt.Args, cty.String)
			if tt.Error != "" {
				require.Error(err)
				require.Contains(err.Error(), tt.Error)
				return
			}

			require.NoError(err)
			require.True(tt.Expected.RawEquals(result), result.GoString())
		})
	}
}

func testGitFixture(t *testing.T, path string) {
	t.Helper()

	// Look for a DOTgit
	original := filepath.Join(path, "DOTgit")
	_, err := os.Stat(original)
	require.NoError(t, err)

	// Rename it
	newPath := filepath.Join(path, ".git")
	require.NoError(t, os.Rename(original, newPath))
	t.Cleanup(func() { os.Rename(newPath, original) })
}
