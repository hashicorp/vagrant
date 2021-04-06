package config

import (
	"github.com/hashicorp/hcl/v2"
)

type Communicator struct {
	Name string `hcl:"name,label"`

	Body   hcl.Body `hcl:",body"`
	Remain hcl.Body `hcl:",remain"`
}
