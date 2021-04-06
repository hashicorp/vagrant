package config

import (
	"github.com/hashicorp/hcl/v2"
)

type Machine struct {
	Name string `hcl:"name,label"`
	Box  string `hcl:"box,label"`

	Body   hcl.Body `hcl:",body"`
	Remain hcl.Body `hcl:",remain"`
}
