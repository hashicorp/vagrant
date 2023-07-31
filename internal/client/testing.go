// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package client

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/singleprocess"
)

// TestBasis returns an initialized client pointing to an in-memory test
// server. This will close automatically on test completion.
//
// This will also change the working directory to a temporary directory
// so that any side effect file creation doesn't impact the real working
// directory. If you need to use your working directory, query it before
// calling this.
func TestBasis(t testing.T, opts ...Option) *Client {
	require := require.New(t)
	client := singleprocess.TestServer(t)

	ctx := context.Background()

	basis, err := New(ctx, WithClient(client), WithLocal())
	require.NoError(err)

	// Move into a temporary directory
	td := testTempDir(t)
	testChdir(t, td)

	return basis
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
