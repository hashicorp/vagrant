// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

import (
	"github.com/hashicorp/hcl/v2"
)

type Vagrant struct {
	Sensitive []string `hcl:"sensitive,optional"`
	Plugins   []string `hcl:"plugins,optional"`
	Host      string   `hcl:"host,optional"`

	Body   hcl.Body `hcl:",body"`
	Remain hcl.Body `hcl:",remain"`
}
