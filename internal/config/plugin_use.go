package config

import (
	"github.com/hashicorp/hcl/v2"
)

// Use is something in the Vagrant configuration that is executed
// using some underlying plugin. This is a general shared structure that is
// used by internal/core to initialize all the proper plugins.
type Use struct {
	Type string   `hcl:",label"`
	Body hcl.Body `hcl:",remain"`
}
