// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package singleprocess

import (
	"context"
	"io"
	"reflect"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"

	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestServiceQueueJob(t *testing.T) {
	ctx := context.Background()

	// Create our server
	impl := TestImpl(t)
	client := server.TestServer(t, impl)

	// Initialize our basis
	TestBasis(t, client, TestBasis(t, client, nil))

	// Simplify writing tests
	type Req = vagrant_server.QueueJobRequest

	t.Run("create success", func(t *testing.T) {
		require := require.New(t)

		// Create, should get an ID back
		resp, err := client.QueueJob(ctx, &Req{
			Job: testJobProto(t, client, nil),
		})
		require.NoError(err)
		require.NotNil(resp)
		require.NotEmpty(resp.JobId)

		// Job should exist and be queued
		job, err := testServiceImpl(impl).state.JobById(resp.JobId, nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_QUEUED, job.State)
	})

	t.Run("expiration", func(t *testing.T) {
		require := require.New(t)

		// Create, should get an ID back
		resp, err := client.QueueJob(ctx, &Req{
			Job:       testJobProto(t, client, nil),
			ExpiresIn: "1ms",
		})
		require.NoError(err)
		require.NotNil(resp)
		require.NotEmpty(resp.JobId)

		// Job should exist and be queued
		require.Eventually(func() bool {
			job, err := testServiceImpl(impl).state.JobById(resp.JobId, nil)
			require.NoError(err)
			return job.State == vagrant_server.Job_ERROR && job.CancelTime != nil
		}, 2*time.Second, 10*time.Millisecond)
	})
}

func TestServiceValidateJob(t *testing.T) {
	ctx := context.Background()

	// Create our server
	client := TestServer(t)

	// Simplify writing tests
	type Req = vagrant_server.ValidateJobRequest

	t.Run("validate success, not assignable", func(t *testing.T) {
		require := require.New(t)

		// Create, should get an ID back
		resp, err := client.ValidateJob(ctx, &Req{
			Job: TestJob(t, client, nil),
		})
		require.NoError(err)
		require.NotNil(resp)
		require.Nil(resp.ValidationError)
		require.True(resp.Valid)
		require.False(resp.Assignable)
	})

	t.Run("invalid", func(t *testing.T) {
		require := require.New(t)

		// Create, should get an ID back
		job := TestJob(t, client, nil)
		job.Id = "HELLO"
		resp, err := client.ValidateJob(ctx, &Req{
			Job: job,
		})
		require.NoError(err)
		require.NotNil(resp)
		require.False(resp.Valid)
		require.False(resp.Assignable)
	})
}

func TestServiceGetJobStream_complete(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	client := TestServer(t)

	// Initialize our basis
	TestBasis(t, client, nil)

	// Create a job
	job := TestJob(t, client, nil)

	// Register our runner
	id, _ := TestRunner(t, client, nil)

	// Start a job request
	runnerStream, err := client.RunnerJobStream(ctx)
	require.NoError(err)
	require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Request_{
			Request: &vagrant_server.RunnerJobStreamRequest_Request{
				RunnerId: id,
			},
		},
	}))

	// Wait for assignment and ack
	{
		resp, err := runnerStream.Recv()
		require.NoError(err)
		assignment, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Assignment)
		require.True(ok, "should be an assignment")
		require.NotNil(assignment)
		require.Equal(job.Id, assignment.Assignment.Job.Id)

		require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
			Event: &vagrant_server.RunnerJobStreamRequest_Ack_{
				Ack: &vagrant_server.RunnerJobStreamRequest_Ack{},
			},
		}))
	}

	// Get our job stream and verify we open
	stream, err := client.GetJobStream(ctx, &vagrant_server.GetJobStreamRequest{JobId: job.Id})
	require.NoError(err)
	{
		resp, err := stream.Recv()
		require.NoError(err)
		open, ok := resp.Event.(*vagrant_server.GetJobStreamResponse_Open_)
		require.True(ok, "should be an open")
		require.NotNil(open)
	}

	// We should receive an initial state change
	{
		resp, err := stream.Recv()
		require.NoError(err)
		state, ok := resp.Event.(*vagrant_server.GetJobStreamResponse_State_)
		require.True(ok, "should be a state change")
		require.NotNil(state)

		require.Equal(vagrant_server.Job_UNKNOWN, state.State.Previous)
		require.NotNil(state.State.Job)
	}

	// We need to give the stream time to initialize the output readers
	// so our output below doesn't become buffered. This isn't really that
	// brittle and 100ms should be more than enough.
	time.Sleep(100 * time.Millisecond)

	// Send some output
	require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Terminal{
			Terminal: &vagrant_server.GetJobStreamResponse_Terminal{
				Events: []*vagrant_server.GetJobStreamResponse_Terminal_Event{
					{
						Event: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line_{
							Line: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line{
								Msg: "hello",
							},
						},
					},
					{
						Event: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line_{
							Line: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line{
								Msg: "world",
							},
						},
					},
				},
			},
		},
	}))

	// Wait for output
	{
		resp := jobStreamRecv(t, stream, (*vagrant_server.GetJobStreamResponse_Terminal_)(nil))
		event := resp.Event.(*vagrant_server.GetJobStreamResponse_Terminal_)
		require.NotNil(event)
		require.False(event.Terminal.Buffered, 2)
		require.Len(event.Terminal.Events, 2)

	}

	// Complete the job
	require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Complete_{
			Complete: &vagrant_server.RunnerJobStreamRequest_Complete{},
		},
	}))

	// Wait for completion
	{
		resp := jobStreamRecv(t, stream, (*vagrant_server.GetJobStreamResponse_Complete_)(nil))
		event := resp.Event.(*vagrant_server.GetJobStreamResponse_Complete_)
		require.NotNil(event)
		require.Nil(event.Complete.Error)
	}
}

func TestServiceGetJobStream_bufferedData(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	client := TestServer(t)

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
	runnerStream, err := client.RunnerJobStream(ctx)
	require.NoError(err)
	require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Request_{
			Request: &vagrant_server.RunnerJobStreamRequest_Request{
				RunnerId: id,
			},
		},
	}))

	// Wait for assignment and ack
	{
		resp, err := runnerStream.Recv()
		require.NoError(err)
		assignment, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Assignment)
		require.True(ok, "should be an assignment")
		require.NotNil(assignment)
		require.Equal(queueResp.JobId, assignment.Assignment.Job.Id)

		require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
			Event: &vagrant_server.RunnerJobStreamRequest_Ack_{
				Ack: &vagrant_server.RunnerJobStreamRequest_Ack{},
			},
		}))
	}

	// Send some output
	require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Terminal{
			Terminal: &vagrant_server.GetJobStreamResponse_Terminal{
				Events: []*vagrant_server.GetJobStreamResponse_Terminal_Event{
					{
						Event: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line_{
							Line: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line{
								Msg: "hello",
							},
						},
					},
					{
						Event: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line_{
							Line: &vagrant_server.GetJobStreamResponse_Terminal_Event_Line{
								Msg: "world",
							},
						},
					},
				},
			},
		},
	}))

	// Complete the job
	require.NoError(runnerStream.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Complete_{
			Complete: &vagrant_server.RunnerJobStreamRequest_Complete{},
		},
	}))

	// Should be done
	_, err = runnerStream.Recv()
	require.Error(err)
	require.Equal(io.EOF, err)

	// Get our job stream and verify we open
	stream, err := client.GetJobStream(ctx,
		&vagrant_server.GetJobStreamRequest{
			JobId: queueResp.JobId,
		},
	)
	require.NoError(err)
	{
		resp, err := stream.Recv()
		require.NoError(err)
		open, ok := resp.Event.(*vagrant_server.GetJobStreamResponse_Open_)
		require.True(ok, "should be an open")
		require.NotNil(open)

	}

	// Wait for output
	{
		resp := jobStreamRecv(t, stream, (*vagrant_server.GetJobStreamResponse_Terminal_)(nil))
		event := resp.Event.(*vagrant_server.GetJobStreamResponse_Terminal_)
		require.NotNil(event)
		require.True(event.Terminal.Buffered)
		require.Len(event.Terminal.Events, 2)

	}

	// Wait for completion
	{
		resp := jobStreamRecv(t, stream, (*vagrant_server.GetJobStreamResponse_Complete_)(nil))
		event := resp.Event.(*vagrant_server.GetJobStreamResponse_Complete_)
		require.Nil(event.Complete.Error)
	}
}

func TestServiceGetJobStream_expired(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)

	// Create our server
	client := TestServer(t)

	// Initialize our basis
	TestBasis(t, client, TestBasis(t, client, nil))

	// Create a job
	queueResp, err := client.QueueJob(ctx,
		&vagrant_server.QueueJobRequest{
			Job:       testJobProto(t, client, nil),
			ExpiresIn: "10ms",
		},
	)
	require.NoError(err)
	require.NotNil(queueResp)
	require.NotEmpty(queueResp.JobId)

	// Get our job stream and verify we open
	stream, err := client.GetJobStream(ctx,
		&vagrant_server.GetJobStreamRequest{
			JobId: queueResp.JobId,
		},
	)
	require.NoError(err)

	// Wait for completion
	{
		resp := jobStreamRecv(t, stream, (*vagrant_server.GetJobStreamResponse_Complete_)(nil))
		event := resp.Event.(*vagrant_server.GetJobStreamResponse_Complete_)
		require.NotNil(event)
		require.Equal(int32(codes.Canceled), event.Complete.Error.Code)
	}
}

// jobStreamRecv receives on the stream until an event of the given
// type is matched.
func jobStreamRecv(
	t *testing.T,
	stream vagrant_server.Vagrant_GetJobStreamClient,
	typ interface{},
) *vagrant_server.GetJobStreamResponse {
	match := reflect.TypeOf(typ)
	for {
		resp, err := stream.Recv()
		require.NoError(t, err)

		if reflect.TypeOf(resp.Event) == match {
			return resp
		}

		t.Logf("received event, but not the type we wanted: %T", resp.Event)
	}
}
