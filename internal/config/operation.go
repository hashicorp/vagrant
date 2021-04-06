package config

import (
	"github.com/mitchellh/mapstructure"
)

// TODO(spox): Pretty sure this can go away but needs to be validated

// Operation is something in the Vagrant configuration that is executed
// using some underlying plugin. This is a general shared structure that is
// used by internal/core to initialize all the proper plugins.
type Operation struct {
	// set internally to note an operation is required for validation
	required bool
}

func (c *Config) Operation() *Operation {
	return mapoperation(c, true)
}

// mapoperation takes a struct that is a superset of Operation and
// maps it down to an Operation. This will panic if this fails.
func mapoperation(input interface{}, req bool) *Operation {
	if input == nil {
		return nil
	}

	var op Operation
	if err := mapstructure.Decode(input, &op); err != nil {
		panic(err)
	}
	op.required = req

	return &op
}
