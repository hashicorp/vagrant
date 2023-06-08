package state

import (
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type VagrantfileFormat uint8

const (
	JSON VagrantfileFormat = VagrantfileFormat(vagrant_server.Vagrantfile_JSON)
	HCL                    = VagrantfileFormat(vagrant_server.Vagrantfile_HCL)
	RUBY                   = VagrantfileFormat(vagrant_server.Vagrantfile_RUBY)
)

type Vagrantfile struct {
	Model

	Format      VagrantfileFormat
	Unfinalized *ProtoValue
	Finalized   *ProtoValue
	Raw         []byte
	Path        *string
}

func init() {
	models = append(models, &Vagrantfile{})
}

func (v *Vagrantfile) ToProto() *vagrant_server.Vagrantfile {
	if v == nil {
		return nil
	}

	var file vagrant_server.Vagrantfile
	if err := decode(v, &file); err != nil {
		panic("failed to decode vagrantfile: " + err.Error())
	}

	return &file
}

func (v *Vagrantfile) UpdateFromProto(vf *vagrant_server.Vagrantfile) *Vagrantfile {
	v.Format = VagrantfileFormat(vf.Format)
	v.Unfinalized = &ProtoValue{Message: vf.Unfinalized}
	v.Finalized = &ProtoValue{Message: vf.Finalized}
	v.Raw = vf.Raw
	if vf.Path != nil {
		v.Path = &vf.Path.Path
	}

	return v
}

func (s *State) VagrantfileFromProto(v *vagrant_server.Vagrantfile) *Vagrantfile {
	var file Vagrantfile

	err := s.decode(v, &file)
	if err != nil {
		panic("failed to decode vagrantfile: " + err.Error())
	}

	return &file
}
