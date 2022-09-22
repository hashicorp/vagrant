package state

import (
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"gorm.io/gorm"
)

type VagrantfileFormat uint8

const (
	JSON VagrantfileFormat = VagrantfileFormat(vagrant_server.Vagrantfile_JSON)
	HCL                    = VagrantfileFormat(vagrant_server.Vagrantfile_HCL)
	RUBY                   = VagrantfileFormat(vagrant_server.Vagrantfile_RUBY)
)

type Vagrantfile struct {
	gorm.Model

	Format      VagrantfileFormat
	Unfinalized *ProtoValue
	Finalized   *ProtoValue
	Raw         []byte
	Path        string
}

func init() {
	models = append(models, &Vagrantfile{})
}

func (v *Vagrantfile) ToProto() *vagrant_server.Vagrantfile {
	if v == nil {
		return nil
	}

	return &vagrant_server.Vagrantfile{
		Format: vagrant_server.Vagrantfile_Format(v.Format),
		Raw:    v.Raw,
		Path: &vagrant_plugin_sdk.Args_Path{
			Path: v.Path,
		},
		Unfinalized: v.Unfinalized.Message.(*vagrant_plugin_sdk.Args_Hash),
		Finalized:   v.Finalized.Message.(*vagrant_plugin_sdk.Args_Hash),
	}
}

func (v *Vagrantfile) UpdateFromProto(vf *vagrant_server.Vagrantfile) *Vagrantfile {
	v.Format = VagrantfileFormat(vf.Format)
	v.Unfinalized = &ProtoRaw{Message: vf.Unfinalized}
	v.Finalized = &ProtoRaw{Message: vf.Finalized}
	v.Raw = vf.Raw
	v.Path = vf.Path.Path
	return v
}

func (s *State) VagrantfileFromProto(v *vagrant_server.Vagrantfile) *Vagrantfile {
	file := &Vagrantfile{
		Format:      VagrantfileFormat(v.Format),
		Unfinalized: &ProtoRaw{Message: v.Unfinalized},
		Finalized:   &ProtoRaw{Message: v.Finalized},
		Raw:         v.Raw,
	}
	if v.Path != nil {
		file.Path = v.Path.Path
	}

	return file
}
