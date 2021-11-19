package config

import (
	"github.com/hashicorp/hcl/v2"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
)

type Project struct {
	// These are new configurations
	Location string            `hcl:"location,attr"`
	Runner   *Runner           `hcl:"runner,block" default:"{}"`
	Labels   map[string]string `hcl:"labels,optional"`

	// These should _roughly_ map to existing Vagrantfile configurations
	Vagrant *Vagrant  `hcl:"vagrant,block"`
	Targets []*Target `hcl:"machine,block"`

	Body   hcl.Body `hcl:",body"`
	Remain hcl.Body `hcl:",remain"`

	path   string
	ref    *vagrant_plugin_sdk.Ref_Project
	config *Config
}

func (p *Project) Ref() *vagrant_plugin_sdk.Ref_Project {
	return p.ref
}

func (p *Project) Validate() (err error) {
	return
}
