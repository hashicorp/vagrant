// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSets(t *testing.T) {
	require := require.New(t)

	var valA, valB int
	sets := NewSets()
	{
		set := sets.NewSet("A")
		set.IntVar(&IntVar{
			Name:   "a",
			Target: &valA,
		})
	}

	{
		set := sets.NewSet("B")
		set.IntVar(&IntVar{
			Name:   "b",
			Target: &valB,
		})
	}

	err := sets.Parse([]string{"-b", "42", "-a", "21"})
	require.NoError(err)

	require.Equal(int(21), valA)
	require.Equal(int(42), valB)
}
