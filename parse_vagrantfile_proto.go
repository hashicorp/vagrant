package main

import (
	"fmt"

	"github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant"

	"github.com/hashicorp/vagrant/go_parse_vagrantfile_ex"
	"github.com/mitchellh/mapstructure"
	"google.golang.org/protobuf/types/known/anypb"
	"google.golang.org/protobuf/types/known/structpb"
)

//go:generate protoc -I .. --go_opt=plugins=grpc --go_out=.. vagrant-ruby/go_parse_vagrantfile_ex/main.proto

func main() {
	// Setup an example proto
	m, _ := structpb.NewValue(map[string]interface{}{
		"source":      ".gitignore",
		"destination": "/.gitignore",
	})
	any, _ := anypb.New(m)

	testProto := &ruby_vagrant.VagrantfileComponents_Vagrantfile{
		Path:           "",
		Raw:            "",
		CurrentVersion: "2",
		MachineConfigs: []*ruby_vagrant.VagrantfileComponents_MachineConfig{
			&ruby_vagrant.VagrantfileComponents_MachineConfig{
				Name: "a",
				ConfigVm: &ruby_vagrant.VagrantfileComponents_ConfigVM{
					Box: "hashicorp/bionic64",
					Provisioners: []*ruby_vagrant.VagrantfileComponents_Provisioner{
						&ruby_vagrant.VagrantfileComponents_Provisioner{
							Name:                 "",
							Type:                 "file",
							Before:               "",
							After:                "",
							CommunicatorRequired: true,
							Config:               any,
						},
					},
				},
			},
		},
	}
	for _, m := range testProto.MachineConfigs {
		fmt.Println("got machine \"" + m.Name + "\"")
		fmt.Println("got box " + m.ConfigVm.Box)
		for _, p := range m.ConfigVm.Provisioners {
			fmt.Println("got provisioner " + p.Type)
			s2, _ := p.Config.UnmarshalNew()
			s2structpb := s2.(*structpb.Value)
			var result go_parse_vagrantfile_ex.FileProvisioner
			s2struct := s2structpb.GetStructValue()
			mapstructure.Decode(s2struct.AsMap(), &result)
			fmt.Println("source: " + result.Source)
			fmt.Println("destination: " + result.Destination)
		}
	}
}
