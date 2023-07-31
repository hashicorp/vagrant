// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestStateBagPutGet(t *testing.T) {
	bag := NewStateBag()

	// Put some values
	bag.Put("a", 1)
	bag.Put("b", "c")
	bag.Put("otherkey", 1.3)

	// Check Get
	require.Equal(t, bag.Get("a"), 1)
	require.Equal(t, bag.Get("b"), "c")
	require.Equal(t, bag.Get("otherkey"), 1.3)
	require.Equal(t, bag.Get("sdfsdl"), nil)

	// Check GetOk
	aval, ok := bag.GetOk("a")
	require.Equal(t, aval, 1)
	require.Equal(t, ok, true)

	bval, ok := bag.GetOk("b")
	require.Equal(t, bval, "c")
	require.Equal(t, ok, true)

	otherkeyval, ok := bag.GetOk("otherkey")
	require.Equal(t, otherkeyval, 1.3)
	require.Equal(t, ok, true)

	badval, ok := bag.GetOk("sdgsadg")
	require.Equal(t, badval, nil)
	require.Equal(t, ok, false)

	// Remove a valid key
	bag.Remove("a")
	aval, ok = bag.GetOk("a")
	require.Equal(t, aval, nil)
	require.Equal(t, ok, false)

	// Remove an invalid key
	bag.Remove("sklajsklgjal")
}
