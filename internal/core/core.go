// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"fmt"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

type closer interface {
	Closer(func() error)
}

// Seed value into plugin as a typed value. This is generally used
// for adding a target or machine to the seeds of a non-cacheable
// plugin
func seedPlugin(
	plugin interface{}, // plugin which implements core.Seeder
	seed interface{}, // value to seed
) (err error) {
	s, ok := plugin.(core.Seeder)
	if !ok {
		return fmt.Errorf("component does not implement core.Seeder")
	}
	seeds, err := s.Seeds()
	if err != nil {
		return
	}

	seeds.AddTyped(seed)

	if err = s.Seed(seeds); err != nil {
		return
	}

	return
}
