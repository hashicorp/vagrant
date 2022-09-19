package singleprocess

import (
	"context"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"google.golang.org/protobuf/types/known/emptypb"
)

func (s *service) UpsertProject(
	ctx context.Context,
	req *vagrant_server.UpsertProjectRequest,
) (*vagrant_server.UpsertProjectResponse, error) {
	result, err := s.state.ProjectPut(req.Project)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertProjectResponse{Project: result}, nil
}

func (s *service) GetProject(
	ctx context.Context,
	req *vagrant_server.GetProjectRequest,
) (*vagrant_server.GetProjectResponse, error) {
	result, err := s.state.ProjectGet(req.Project)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.GetProjectResponse{Project: result}, nil
}

func (s *service) FindProject(
	ctx context.Context,
	req *vagrant_server.FindProjectRequest,
) (*vagrant_server.FindProjectResponse, error) {
	result, err := s.state.ProjectFind(req.Project)
	if err != nil {
		return nil, err
	}

	return &vagrant_server.FindProjectResponse{Project: result}, nil
}

func (s *service) ListProjects(
	ctx context.Context,
	req *emptypb.Empty,
) (*vagrant_server.ListProjectsResponse, error) {
	result, err := s.state.ProjectList()
	if err != nil {
		return nil, err
	}

	return &vagrant_server.ListProjectsResponse{Projects: result}, nil
}
