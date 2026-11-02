// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package clicontext

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestStorage_workflow(t *testing.T) {
	require := require.New(t)

	st := TestStorage(t)

	// Initially empty
	{
		list, err := st.List()
		require.NoError(err)
		require.Empty(list)

		def, err := st.Default()
		require.NoError(err)
		require.Empty(def)
	}

	// Add a context
	cfg := &Config{}
	require.NoError(st.Set("hello", cfg))

	// Should not be empty anymore
	{
		list, err := st.List()
		require.NoError(err)
		require.Len(list, 1)
		require.Equal("hello", list[0])
	}

	{
		// Should be the default since we didn't have one before.
		def, err := st.Default()
		require.NoError(err)
		require.Equal("hello", def)
	}

	// Should be able to load
	{
		actual, err := st.Load("hello")
		require.NoError(err)
		require.Equal(cfg, actual)
	}

	// Should be able to rename
	{
		err := st.Rename("hello", "goodbye")
		require.NoError(err)

		// Should be the default since we didn't have one before.
		def, err := st.Default()
		require.NoError(err)
		require.Equal("goodbye", def)

		// Should only have this one
		list, err := st.List()
		require.NoError(err)
		require.Len(list, 1)
		require.Equal("goodbye", list[0])
	}

	// Should be able to delete
	require.NoError(st.Delete("goodbye"))

	// Should be empty again
	{
		list, err := st.List()
		require.NoError(err)
		require.Empty(list)

		def, err := st.Default()
		require.NoError(err)
		require.Empty(def)
	}
}

func TestStorage_workflowNoSymlink(t *testing.T) {
	require := require.New(t)

	st := TestStorage(t)
	st.noSymlink = true

	// Initially empty
	{
		list, err := st.List()
		require.NoError(err)
		require.Empty(list)

		def, err := st.Default()
		require.NoError(err)
		require.Empty(def)
	}

	// Add a context
	cfg := &Config{}
	require.NoError(st.Set("hello", cfg))

	// Should not be empty anymore
	{
		list, err := st.List()
		require.NoError(err)
		require.Len(list, 1)
		require.Equal("hello", list[0])
	}

	{
		// Should be the default since we didn't have one before.
		def, err := st.Default()
		require.NoError(err)
		require.Equal("hello", def)
	}

	// Should be able to load
	{
		actual, err := st.Load("hello")
		require.NoError(err)
		require.Equal(cfg, actual)
	}

	// Should be able to rename
	{
		err := st.Rename("hello", "goodbye")
		require.NoError(err)

		// Should be the default since we didn't have one before.
		def, err := st.Default()
		require.NoError(err)
		require.Equal("goodbye", def)

		// Should only have this one
		list, err := st.List()
		require.NoError(err)
		require.Len(list, 1)
		require.Equal("goodbye", list[0])
	}

	// Should be able to delete
	require.NoError(st.Delete("goodbye"))

	// Should be empty again
	{
		list, err := st.List()
		require.NoError(err)
		require.Empty(list)

		def, err := st.Default()
		require.NoError(err)
		require.Empty(def)
	}
}

func TestStorage_deleteNonExist(t *testing.T) {
	require := require.New(t)

	st := TestStorage(t)
	require.NoError(st.Delete("nope"))
}
