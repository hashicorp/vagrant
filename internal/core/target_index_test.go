package core

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestTargetIndexDelete(t *testing.T) {
	tp := TestMinimalProject(t)
	ti, err := tp.TargetIndex()
	if err != nil {
		t.Error(err)
	}

	// No Targets
	err = ti.Delete("")
	require.NoError(t, err)

	// Add targets
	projectTargets(t, tp, 3)

	// Includes by target name
	err = ti.Delete("target-1")
	require.NoError(t, err)

	// Includes by target id
	err = ti.Delete("uuid-2")
	require.NoError(t, err)
}

func TestTargetIndexGet(t *testing.T) {
	tp := TestMinimalProject(t)
	ti, err := tp.TargetIndex()
	if err != nil {
		t.Error(err)
	}

	// No Targets
	target, err := ti.Get("")
	require.Error(t, err)
	require.Nil(t, target)

	// Add targets
	projectTargets(t, tp, 3)

	// Get by target id
	target, err = ti.Get("uuid-1")
	require.NoError(t, err)
	name, _ := target.Name()
	require.Equal(t, name, "target-1")
}

func TestTargetIndexIncludes(t *testing.T) {
	tp := TestMinimalProject(t)
	ti, err := tp.TargetIndex()
	if err != nil {
		t.Error(err)
	}

	// No Targets
	exists, err := ti.Includes("")
	require.NoError(t, err)
	require.False(t, exists)

	// Add targets
	projectTargets(t, tp, 3)

	// Includes by target id
	exists, err = ti.Includes("uuid-1")
	require.NoError(t, err)
	require.True(t, exists)
}

func TestTargetIndexSet(t *testing.T) {
	tp := TestMinimalProject(t)
	ti, err := tp.TargetIndex()
	if err != nil {
		t.Error(err)
	}

	tt := TestMinimalTarget(t)

	tt.target.Name = "newName"
	updated, err := ti.Set(tt)
	require.NoError(t, err)
	updateName, _ := updated.Name()
	require.Equal(t, updateName, "newName")
}

func TestTargetIndexAll(t *testing.T) {
	tp := TestMinimalProject(t)
	ti, err := tp.TargetIndex()
	if err != nil {
		t.Error(err)
	}

	// No Targets
	targets, err := ti.All()
	require.NoError(t, err)
	require.Len(t, targets, 0)

	// Add targets
	projectTargets(t, tp, 3)

	// Includes by target name
	targets, err = ti.All()
	require.NoError(t, err)
	require.Len(t, targets, 3)
}
