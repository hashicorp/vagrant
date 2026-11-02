// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package clicontext

import (
	"io"

	"github.com/hashicorp/hcl/v2/gohcl"
	"github.com/hashicorp/hcl/v2/hclsimple"
	"github.com/hashicorp/hcl/v2/hclwrite"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant/internal/serverconfig"
)

// Config is the structure of the context configuration file. This structure
// can be decoded with hclsimple.DecodeFile.
type Config struct {
	// Server is the configuration to talk to a Vagrant server.
	Server serverconfig.Client `hcl:"server,block"`
}

// LoadPath loads a context configuration from a filepath.
func LoadPath(p path.Path) (*Config, error) {
	var cfg Config
	err := hclsimple.DecodeFile(p.String(), nil, &cfg)
	return &cfg, err
}

// WriteTo implements io.WriterTo and encodes this config as HCL.
func (c *Config) WriteTo(w io.Writer) (int64, error) {
	f := hclwrite.NewFile()
	gohcl.EncodeIntoBody(c, f.Body())
	return f.WriteTo(w)
}
