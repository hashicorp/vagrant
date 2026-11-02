// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package clicontext

import (
	"io/ioutil"
	"os"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
)

// TestStorage returns a *Storage pointed at a temporary directory. This
// will cleanup automatically by using t.Cleanup.
func TestStorage(t testing.T) *Storage {
	td, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	st, err := NewStorage(WithDir(path.NewPath(td)))
	require.NoError(t, err)

	return st
}
