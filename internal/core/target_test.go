package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestTargetSpecializeMachine(t *testing.T) {
	tt := TestMinimalTarget(t)
	specialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	if _, ok := specialized.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}

	// Get machine from the cache, should be the same machine
	reSpecialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	require.Equal(t, reSpecialized, specialized)
}

func TestTargetSpecializeMultiMachine(t *testing.T) {
	p := TestMinimalProject(t)
	tt1 := TestTarget(t, p, &vagrant_server.Target{Name: "tt1"})
	tt2 := TestTarget(t, p, &vagrant_server.Target{Name: "tt2"})

	specialized, err := tt1.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	if _, ok := specialized.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}
	specializedName, _ := specialized.(core.Machine).Name()

	specialized2, err := tt2.Specialize((*core.Machine)(nil))
	if err != nil {
		t.Errorf("Specialize function returned an error")
	}
	if _, ok := specialized2.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}
	specialized2Name, _ := specialized2.(core.Machine).Name()

	require.NotEqual(t, specializedName, specialized2Name)
}

func TestTargetSpecializeBad(t *testing.T) {
	tt := TestMinimalTarget(t)
	specialized, err := tt.Specialize((*core.Project)(nil))

	if err != nil {
		t.Errorf("Specialize function returned an error")
	}

	if specialized != nil {
		t.Errorf("Should not specialize to an unsupported type")
	}
}
