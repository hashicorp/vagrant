package singleprocess

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/server/singleprocess/state"
)

func (s *service) UpsertTask(
	ctx context.Context,
	req *vagrant_server.UpsertTaskRequest,
) (*vagrant_server.UpsertTaskResponse, error) {
	result := req.Task

	// If we have no ID, then we're inserting and need to generate an ID.
	insert := result.Id == ""
	if insert {
		// Get the next id
		id, err := server.Id()
		if err != nil {
			return nil, status.Errorf(codes.Internal, "uuid generation failed: %s", err)
		}

		// Specify the id
		result.Id = id
	}

	if err := s.state.TaskPut(!insert, result); err != nil {
		return nil, err
	}

	return &vagrant_server.UpsertTaskResponse{Task: result}, nil
}

// TODO: test
func (s *service) ListTasks(
	ctx context.Context,
	req *vagrant_server.ListTasksRequest,
) (*vagrant_server.ListTasksResponse, error) {
	result, err := s.state.TaskList(req.Scope,
		state.ListWithStatusFilter(req.Status...),
		state.ListWithOrder(req.Order),
		state.ListWithPhysicalState(req.PhysicalState),
	)

	if err != nil {
		return nil, err
	}

	return &vagrant_server.ListTasksResponse{Tasks: result}, nil
}

// TODO: test
func (s *service) GetLatestTask(
	ctx context.Context,
	req *vagrant_server.GetLatestTaskRequest,
) (*vagrant_server.Task, error) {
	return s.state.TaskLatest(req.Scope)
}

// GetTask returns a Task based on ID
func (s *service) GetTask(
	ctx context.Context,
	req *vagrant_server.GetTaskRequest,
) (*vagrant_server.Task, error) {
	return s.state.TaskGet(req.Ref)
}
