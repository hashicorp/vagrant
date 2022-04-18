package core

import (
	"fmt"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

type closer interface {
	Closer(func() error)
}

func seedPlugin(
	plugin interface{},
	seed interface{},
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
