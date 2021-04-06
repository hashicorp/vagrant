package singleprocess

import (
	"context"
	"strings"

	"github.com/golang/protobuf/ptypes/empty"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

func (s *service) MachineNames(
	ctx context.Context,
	in *empty.Empty,
) (result *vagrant_plugin_sdk.Project_MachineNamesResponse, err error) {
	machines, err := s.state.MachineList()
	if err != nil {
		return nil, err
	}

	machineNames := []string{}
	for _, m := range machines {
		sanatizedName := strings.Split(m.Name, "+")[1]
		machineNames = append(machineNames, sanatizedName)
	}
	return &vagrant_plugin_sdk.Project_MachineNamesResponse{
		Names: machineNames,
	}, nil
}

func (s *service) ActiveMachines(
	ctx context.Context,
	in *vagrant_plugin_sdk.Project_ActiveMachinesRequest,
) (result *vagrant_plugin_sdk.Project_ActiveMachinesResponse, err error) {
	machines := []*vagrant_plugin_sdk.Project_MachineAndProvider{}

	p, err := s.state.ProjectGet(&vagrant_server.Ref_Project{
		ResourceId: in.Env.ProjectId,
	})
	pp := serverptypes.Project{Project: p}
	for _, m := range pp.Project.Machines {
		machine, err := s.state.MachineGet(m)
		if err != nil {
			// Machine not found
		}
		machines = append(machines,
			&vagrant_plugin_sdk.Project_MachineAndProvider{Name: machine.Name, Provider: machine.Provider})
	}

	return &vagrant_plugin_sdk.Project_ActiveMachinesResponse{
		Machines: machines,
	}, nil
}
