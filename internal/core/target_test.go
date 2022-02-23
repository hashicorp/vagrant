package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

func TestTargetSpecializeMachine(t *testing.T) {
	tt, _ := TestMinimalTarget(t)
	specialized, err := tt.Specialize((*core.Machine)(nil))

	if err != nil {
		t.Errorf("Specialize function returned an error")
	}

	if _, ok := specialized.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}
}

func TestTargetSpecializeBad(t *testing.T) {
	tt, _ := TestMinimalTarget(t)
	specialized, err := tt.Specialize((*core.Project)(nil))

	if err != nil {
		t.Errorf("Specialize function returned an error")
	}

	if specialized != nil {
		t.Errorf("Should not specialize to an unsupported type")
	}
}
