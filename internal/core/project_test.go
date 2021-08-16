package core

import (
	"testing"
)

func TestNewProject(t *testing.T) {
	tp := TestProject(t)
	vn := tp.Ref()
	if vn == nil {
		t.Errorf("Creating project failed")
	}
}
