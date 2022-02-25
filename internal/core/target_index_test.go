package core

import (
	"testing"

	"github.com/stretchr/testify/require"
)

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

	// Get by target name
	target, err = ti.Get("target-1")
	require.NoError(t, err)
	rid, _ := target.ResourceId()
	require.Equal(t, rid, "id-1")

	// Get by target id
	target, err = ti.Get("uuid-1")
	require.NoError(t, err)
	name, _ := target.Name()
	require.Equal(t, name, "target-1")
}
