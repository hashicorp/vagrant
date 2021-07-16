package core

import (
	"testing"
)

func TestNewProject(t *testing.T) {
	tp := TestProject(t)
	vn, err := tp.VagrantfileName()
	if err != nil {
		t.Errorf("there was an error")
	}
	if vn != "VagrantFile" {
		t.Errorf("idfk")
	}
}
