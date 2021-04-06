package config

import (
	"github.com/hashicorp/hcl/v2"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Basis struct {
	// These are new configurations
	Location string            `hcl:"location,attr"`
	Runner   *Runner           `hcl:"runner,block" default:"{}"`
	Labels   map[string]string `hcl:"labels,optional"`

	// These should _roughly_ map to existing Vagrantfile configurations
	Vagrant       *Vagrant        `hcl:"vagrant,block"`
	Machines      []*Machine      `hcl:"machine,block"`
	Communicators []*Communicator `hcl:"communicator,block"`

	Body   hcl.Body `hcl:",body"`
	Remain hcl.Body `hcl:",remain"`

	ref    *vagrant_server.Basis
	path   string
	config *Config
}

func (b *Basis) Ref() *vagrant_server.Basis {
	return b.ref
}

func (b *Basis) Validate() (err error) {
	return
}
