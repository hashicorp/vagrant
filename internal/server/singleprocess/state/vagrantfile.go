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

	vf := &vagrant_server.Vagrantfile{
		Format: vagrant_server.Vagrantfile_Format(v.Format),
		Raw:    v.Raw,
	}
	if len(v.Path) > 0 {
		vf.Path = &vagrant_plugin_sdk.Args_Path{
			Path: v.Path,
		}
	}
	if v.Unfinalized != nil {
		vf.Unfinalized = v.Unfinalized.Message.(*vagrant_plugin_sdk.Args_Hash)
	}
	if v.Finalized != nil {
		vf.Finalized = v.Finalized.Message.(*vagrant_plugin_sdk.Args_Hash)
	}

	return vf
}

func (v *Vagrantfile) UpdateFromProto(vf *vagrant_server.Vagrantfile) *Vagrantfile {
	v.Format = VagrantfileFormat(vf.Format)
	v.Raw = vf.Raw
	if vf.Unfinalized != nil {
		v.Unfinalized = &ProtoValue{Message: vf.Unfinalized}
	}
	if vf.Finalized != nil {
		v.Finalized = &ProtoValue{Message: vf.Finalized}
	}
	if vf.Path != nil {
		v.Path = vf.Path.Path
	}
	return v
}

func (s *State) VagrantfileFromProto(v *vagrant_server.Vagrantfile) *Vagrantfile {
	file := &Vagrantfile{
		Format: VagrantfileFormat(v.Format),
		Raw:    v.Raw,
	}
	if v.Unfinalized != nil {
		file.Unfinalized = &ProtoValue{Message: v.Unfinalized}
	}
	if v.Finalized != nil {
		file.Finalized = &ProtoValue{Message: v.Finalized}
	}
	if v.Path != nil {
		file.Path = v.Path.Path
	}

	return file
}
