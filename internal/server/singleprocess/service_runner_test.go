// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

import (
	"context"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// Complete happy path job stream
func TestServiceRunnerJobStream_complete(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	impl := TestImpl(t)
	client := server.TestServer(t, impl)

	// Initialize our basis
	TestBasis(t, client, nil)

	// Create a job
	queueResp, err := client.QueueJob(ctx,
		&vagrant_server.QueueJobRequest{
			Job: testJobProto(t, client, nil),
		},
	)
	require.NoError(err)
	require.NotNil(queueResp)
	require.NotEmpty(queueResp.JobId)

	// Register our runner
	id, _ := TestRunner(t, client, nil)

	// Start a job request
	stream, err := client.RunnerJobStream(ctx)
	require.NoError(err)
	require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Request_{
			Request: &vagrant_server.RunnerJobStreamRequest_Request{
				RunnerId: id,
			},
		},
	}))

	// Wait for assignment and ack
	{
		resp, err := stream.Recv()
		require.NoError(err)
		assignment, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Assignment)
		require.True(ok, "should be an assignment")
		require.NotNil(assignment)
		require.Equal(queueResp.JobId, assignment.Assignment.Job.Id)

		require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
			Event: &vagrant_server.RunnerJobStreamRequest_Ack_{
				Ack: &vagrant_server.RunnerJobStreamRequest_Ack{},
			},
		}))
	}

	// Complete the job
	require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Complete_{
			Complete: &vagrant_server.RunnerJobStreamRequest_Complete{},
		},
	}))

	// Should be done
	_, err = stream.Recv()
	require.Error(err)
	require.Equal(io.EOF.Error(), err.Error())

	// Query our job and it should be done
	job, err := testServiceImpl(impl).state.JobById(queueResp.JobId, nil)
	require.NoError(err)
	require.Equal(vagrant_server.Job_SUCCESS, job.State)
}

func TestServiceRunnerJobStream_badOpen(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	client := TestServer(t)

	// Start exec with a bad starting message
	stream, err := client.RunnerJobStream(ctx)
	require.NoError(err)
	require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Ack_{
			Ack: &vagrant_server.RunnerJobStreamRequest_Ack{},
		},
	}))

	// Wait for data
	resp, err := stream.Recv()
	require.Error(err)
	require.Equal(codes.FailedPrecondition, status.Code(err))
	require.Nil(resp)
}

func TestServiceRunnerJobStream_errorBeforeAck(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	impl := TestImpl(t)
	client := server.TestServer(t, impl)

	// Initialize our basis
	TestBasis(t, client, TestBasis(t, client, nil))

	// Create a job
	queueResp, err := client.QueueJob(ctx,
		&vagrant_server.QueueJobRequest{
			Job: testJobProto(t, client, nil),
		},
	)
	require.NoError(err)
	require.NotNil(queueResp)
	require.NotEmpty(queueResp.JobId)

	// Register our runner
	id, _ := TestRunner(t, client, nil)

	// Start a job request
	stream, err := client.RunnerJobStream(ctx)
	require.NoError(err)
	require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Request_{
			Request: &vagrant_server.RunnerJobStreamRequest_Request{
				RunnerId: id,
			},
		},
	}))

	// Wait for assignment and DONT ack, send an error instead
	{
		resp, err := stream.Recv()
		require.NoError(err)
		assignment, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Assignment)
		require.True(ok, "should be an assignment")
		require.NotNil(assignment)
		require.Equal(queueResp.JobId, assignment.Assignment.Job.Id)

		require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
			Event: &vagrant_server.RunnerJobStreamRequest_Error_{
				Error: &vagrant_server.RunnerJobStreamRequest_Error{
					Error: status.Newf(codes.Unknown, "error").Proto(),
				},
			},
		}))
	}

	// Should be done
	_, err = stream.Recv()
	require.Error(err)
	require.Equal(io.EOF, err)

	// Query our job and it should be queued again
	job, err := testServiceImpl(impl).state.JobById(queueResp.JobId, nil)
	require.NoError(err)
	require.Equal(vagrant_server.Job_QUEUED, job.State)
}

// Complete happy path job stream
func TestServiceRunnerJobStream_cancel(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	impl := TestImpl(t)
	client := server.TestServer(t, impl)

	// Initialize our basis
	TestBasis(t, client, nil)

	// Create a job
	queueResp, err := client.QueueJob(ctx,
		&vagrant_server.QueueJobRequest{
			Job: testJobProto(t, client, nil),
		},
	)
	require.NoError(err)
	require.NotNil(queueResp)
	require.NotEmpty(queueResp.JobId)

	// Register our runner
	id, _ := TestRunner(t, client, nil)

	// Start a job request
	stream, err := client.RunnerJobStream(ctx)
	require.NoError(err)
	require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Request_{
			Request: &vagrant_server.RunnerJobStreamRequest_Request{
				RunnerId: id,
			},
		},
	}))

	// Wait for assignment and ack
	{
		resp, err := stream.Recv()
		require.NoError(err)
		assignment, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Assignment)
		require.True(ok, "should be an assignment")
		require.NotNil(assignment)
		require.Equal(queueResp.JobId, assignment.Assignment.Job.Id)

		require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
			Event: &vagrant_server.RunnerJobStreamRequest_Ack_{
				Ack: &vagrant_server.RunnerJobStreamRequest_Ack{},
			},
		}))
	}

	// Cancel the job
	_, err = client.CancelJob(ctx, &vagrant_server.CancelJobRequest{JobId: queueResp.JobId})
	require.NoError(err)

	// Wait for the cancel event
	{
		resp, err := stream.Recv()
		require.NoError(err)
		_, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Cancel)
		require.True(ok, "should be an assignment")
	}

	// Complete the job
	require.NoError(stream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Complete_{
			Complete: &vagrant_server.RunnerJobStreamRequest_Complete{},
		},
	}))

	// Should be done
	_, err = stream.Recv()
	require.Error(err)
	require.Equal(io.EOF, err, err.Error())

	// Query our job and it should be done
	job, err := testServiceImpl(impl).state.JobById(queueResp.JobId, nil)
	require.NoError(err)
	require.Equal(vagrant_server.Job_SUCCESS, job.State)
	require.NotEmpty(job.CancelTime)
}
