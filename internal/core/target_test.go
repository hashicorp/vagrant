package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

func TestTargetSpecializeMachine(t *testing.T) {
	tt, _ := TestTarget(t)
	specialized, err := tt.Specialize((*core.Machine)(nil))

	if err != nil {
		t.Errorf("Specialize function returned an error")
	}

	if _, ok := specialized.(core.Machine); !ok {
		t.Errorf("Unable to specialize a target to a machine")
	}
}

func TestTargetSpecializeBad(t *testing.T) {
	tt, _ := TestTarget(t)
	specialized, err := tt.Specialize((*core.Project)(nil))

	if err != nil {
		t.Errorf("Specialize function returned an error")
	}

	if specialized != nil {
		t.Errorf("Should not specialize to an unsupported type")
	}
}

func TestRun(t *testing.T) {
	// TODO: needs
	// - to be able to create a Task
	// tt, _ := TestTarget(t)
	// ctx := context.Background()
	// tk := &vagrant_server.Task{}

	// err := tt.Run(ctx, tk)
	// if err != nil {
	// 	t.Errorf("Run returned an error")
	// }
}
