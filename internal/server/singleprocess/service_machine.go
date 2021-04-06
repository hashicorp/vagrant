package singleprocess

import (
	"context"

	"github.com/golang/protobuf/ptypes/empty"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// TODO: test
func (s *service) UpsertMachine(
	ctx context.Context,
	req *vagrant_server.UpsertMachineRequest,
) (*vagrant_server.UpsertMachineResponse, error) {
	m, err := s.state.MachinePut(req.Machine)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertMachineResponse{Machine: m}, nil
}

// TODO: test
func (s *service) GetMachine(
	ctx context.Context,
	req *vagrant_server.GetMachineRequest,
) (*vagrant_server.GetMachineResponse, error) {
	result, err := s.state.MachineGet(req.Machine)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.GetMachineResponse{Machine: result}, nil
}

func (s *service) FindMachine(
	ctx context.Context,
	req *vagrant_server.FindMachineRequest,
) (*vagrant_server.FindMachineResponse, error) {
	result, err := s.state.MachineFind(req.Machine)
	if err != nil {
		return nil, err
	}
	return &vagrant_server.FindMachineResponse{Machine: result, Found: true}, nil
}

// TODO: test
func (s *service) ListMachines(
	ctx context.Context,
	req *empty.Empty,
) (*vagrant_server.ListMachinesResponse, error) {
	result, err := s.state.MachineList()
	if err != nil {
		return nil, err
	}

	return &vagrant_server.ListMachinesResponse{Machines: result}, nil
}
