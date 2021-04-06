package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (s *service) Box(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_BoxRequest,
) (result *vagrant_plugin_sdk.Machine_BoxResponse, err error) {
	// TODO: actually get the box!

	// m, err := s.state.MachineGet(
	// 	&vagrant_server.Ref_Machine{
	// 		ResourceId: in.Machine.ResourceId,
	// 	},
	// )
	// if err != nil {
	// 	return
	// }

	dataPath, _ := paths.VagrantHome()

	fakeBox := &vagrant_plugin_sdk.Args_Box{
		Name:        "hashicorp/bionic64",
		Provider:    "virtualbox",
		Version:     "1.0.282",
		Directory:   dataPath.String() + "/boxes/hashicorp-VAGRANTSLASH-bionic64/1.0.282/virtualbox",
		Metadata:    map[string]string{},
		MetadataUrl: "https://vagrantcloud.com/hashicorp/bionic64",
	}

	return &vagrant_plugin_sdk.Machine_BoxResponse{
		// Box: m.Box,
		Box: fakeBox,
	}, nil
}

func (s *service) SetName(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_SetNameRequest,
) (result *vagrant_plugin_sdk.Machine_SetNameResponse, err error) {
	return
}

func (s *service) GetName(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_GetNameRequest,
) (result *vagrant_plugin_sdk.Machine_GetNameResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}

	return &vagrant_plugin_sdk.Machine_GetNameResponse{
		Name: m.Name,
	}, nil
}

func (s *service) SetID(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_SetIDRequest,
) (result *vagrant_plugin_sdk.Machine_SetIDResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}
	m.Id = in.Id
	_, err = s.state.MachinePut(m)
	return &vagrant_plugin_sdk.Machine_SetIDResponse{}, err
}

func (s *service) GetID(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_GetIDRequest,
) (result *vagrant_plugin_sdk.Machine_GetIDResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}

	return &vagrant_plugin_sdk.Machine_GetIDResponse{
		Id: m.Id,
	}, nil
}

func (s *service) Datadir(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_DatadirRequest,
) (result *vagrant_plugin_sdk.Machine_DatadirResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}

	return &vagrant_plugin_sdk.Machine_DatadirResponse{
		Datadir: m.Datadir,
	}, nil
}

func (s *service) LocalDataPath(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_LocalDataPathRequest,
) (result *vagrant_plugin_sdk.Machine_LocalDataPathResponse, err error) {
	return
}

func (s *service) Provider(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_ProviderRequest,
) (result *vagrant_plugin_sdk.Machine_ProviderResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}

	return &vagrant_plugin_sdk.Machine_ProviderResponse{
		Provider: m.Provider,
	}, nil
}

func (s *service) VagrantfileName(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_VagrantfileNameRequest,
) (result *vagrant_plugin_sdk.Machine_VagrantfileNameResponse, err error) {
	return
}

func (s *service) VagrantfilePath(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_VagrantfilePathRequest,
) (result *vagrant_plugin_sdk.Machine_VagrantfilePathResponse, err error) {
	return
}

func (s *service) UpdatedAt(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_UpdatedAtRequest,
) (result *vagrant_plugin_sdk.Machine_UpdatedAtResponse, err error) {
	return
}

func (s *service) UI(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_UIRequest,
) (result *vagrant_plugin_sdk.Machine_UIResponse, err error) {
	return
}

func (s *service) GetState(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_GetStateRequest,
) (result *vagrant_plugin_sdk.Machine_GetStateResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}

	return &vagrant_plugin_sdk.Machine_GetStateResponse{
		State: m.State,
	}, nil

}

func (s *service) GetUUID(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_GetUUIDRequest,
) (result *vagrant_plugin_sdk.Machine_GetUUIDResponse, err error) {
	return &vagrant_plugin_sdk.Machine_GetUUIDResponse{
		Uuid: "XXXXXXXXX",
	}, nil
}

func (s *service) SetUUID(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_SetUUIDRequest,
) (result *vagrant_plugin_sdk.Machine_SetUUIDResponse, err error) {
	return
}

func (s *service) SetState(
	ctx context.Context,
	in *vagrant_plugin_sdk.Machine_SetStateRequest,
) (result *vagrant_plugin_sdk.Machine_SetStateResponse, err error) {
	m, err := s.state.MachineGet(
		&vagrant_server.Ref_Machine{
			ResourceId: in.Machine.ResourceId,
		},
	)
	if err != nil {
		return
	}

	m.State = in.State
	_, err = s.state.MachinePut(m)
	return &vagrant_plugin_sdk.Machine_SetStateResponse{}, err
}
