package state

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/go-memdb"
	//	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

func TestJobAssign(t *testing.T) {
	t.Run("basic assignment with one", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// We should not have an output buffer yet
		require.Nil(job.OutputBuffer)

		// Should block if requesting another since none exist
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		job, err = s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
		require.Error(err)
		require.Nil(job)
		require.Equal(ctx.Err(), err)
	})

	t.Run("blocking on any", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		{
			job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
			require.NoError(err)
			require.NotNil(job)
			require.Equal("A", job.Id)
		}

		// Get the next value in a goroutine
		{
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			var job *Job
			var jerr error
			doneCh := make(chan struct{})
			go func() {
				defer close(doneCh)
				job, jerr = s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
			}()

			// We should be blocking
			select {
			case <-doneCh:
				t.Fatal("should wait")

			case <-time.After(500 * time.Millisecond):
			}

			// Insert another job
			require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
				Id: "B",
				Scope: &vagrant_server.Job_Project{
					Project: projRef,
				},
			})))

			// We should get a result
			select {
			case <-doneCh:

			case <-time.After(500 * time.Millisecond):
				t.Fatal("should have a result")
			}

			require.NoError(jerr)
			require.NotNil(job)
			require.Equal("B", job.Id)
		}
	})

	// t.Run("blocking on matching basis and project", func(t *testing.T) {
	// 	require := require.New(t)

	// 	s := TestState(t)
	// 	defer s.Close()

	// 	// Create two builds for the same project
	// 	require.NoError(s.JobCreate(serverptypes.TestJobNew(t, &vagrant_server.Job{
	// 		Id: "A",
	// 		Project: &vagrant_plugin_sdk.Ref_Project{
	// 			ResourceId: "project1",
	// 		},
	// 		Operation: &vagrant_server.Job_Run{
	// 			Run: &vagrant_server.Job_RunOp{},
	// 		},
	// 	})))
	// 	require.NoError(s.JobCreate(serverptypes.TestJobNew(t, &vagrant_server.Job{
	// 		Id: "B",
	// 		Project: &vagrant_plugin_sdk.Ref_Project{
	// 			ResourceId: "project1",
	// 		},
	// 		Operation: &vagrant_server.Job_Run{
	// 			Run: &vagrant_server.Job_RunOp{},
	// 		},
	// 	})))

	// 	// Assign it, we should get this build
	// 	{
	// 		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
	// 		require.NoError(err)
	// 		require.NotNil(job)
	// 		require.Equal("A", job.Id)
	// 	}

	// 	// Get the next value in a goroutine
	// 	{
	// 		ctx, cancel := context.WithCancel(context.Background())
	// 		defer cancel()
	// 		var job *Job
	// 		var jerr error
	// 		doneCh := make(chan struct{})
	// 		go func() {
	// 			defer close(doneCh)
	// 			job, jerr = s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
	// 		}()

	// 		// We should be blocking
	// 		select {
	// 		case <-doneCh:
	// 			t.Fatal("should wait")

	// 		case <-time.After(500 * time.Millisecond):
	// 		}

	// 		// Insert another job for a different workspace
	// 		require.NoError(s.JobCreate(serverptypes.TestJobNew(t, &vagrant_server.Job{
	// 			Id: "C",
	// 			Project: &vagrant_plugin_sdk.Ref_Project{
	// 				ResourceId: "project2",
	// 			},
	// 			Operation: &vagrant_server.Job_Run{
	// 				Run: &vagrant_server.Job_RunOp{},
	// 			},
	// 		})))

	// 		// We should get a result
	// 		select {
	// 		case <-doneCh:

	// 		case <-time.After(500 * time.Millisecond):
	// 			t.Fatal("should have a result")
	// 		}

	// 		require.NoError(jerr)
	// 		require.NotNil(job)
	// 		require.Equal("C", job.Id)
	// 	}
	// })

	// t.Run("blocking on matching basis and project (sequential)", func(t *testing.T) {
	// 	require := require.New(t)

	// 	s := TestState(t)
	// 	defer s.Close()

	// 	// Create two builds for the same app/workspace
	// 	require.NoError(s.JobCreate(serverptypes.TestJobNew(t, &vagrant_server.Job{
	// 		Id: "A",
	// 		Project: &vagrant_plugin_sdk.Ref_Project{
	// 			ResourceId: "project1",
	// 		},
	// 		Operation: &vagrant_server.Job_Run{
	// 			Run: &vagrant_server.Job_RunOp{},
	// 		},
	// 	})))
	// 	require.NoError(s.JobCreate(serverptypes.TestJobNew(t, &vagrant_server.Job{
	// 		Id: "B",
	// 		Project: &vagrant_plugin_sdk.Ref_Project{
	// 			ResourceId: "project1",
	// 		},
	// 		Operation: &vagrant_server.Job_Run{
	// 			Run: &vagrant_server.Job_RunOp{},
	// 		},
	// 	})))

	// 	// Assign it, we should get this build
	// 	job1, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
	// 	require.NoError(err)
	// 	require.NotNil(job1)
	// 	require.Equal("A", job1.Id)

	// 	// Get the next value in a goroutine
	// 	{
	// 		ctx, cancel := context.WithCancel(context.Background())
	// 		defer cancel()
	// 		var job *Job
	// 		var jerr error
	// 		doneCh := make(chan struct{})
	// 		go func() {
	// 			defer close(doneCh)
	// 			job, jerr = s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
	// 		}()

	// 		// We should be blocking
	// 		select {
	// 		case <-doneCh:
	// 			t.Fatal("should wait")

	// 		case <-time.After(500 * time.Millisecond):
	// 		}

	// 		// Complete the job
	// 		_, err = s.JobAck(job1.Id, true)
	// 		require.NoError(err)
	// 		require.NoError(s.JobComplete(job1.Id, nil, nil))

	// 		// We should get a result
	// 		select {
	// 		case <-doneCh:

	// 		case <-time.After(500 * time.Millisecond):
	// 			t.Fatal("should have a result")
	// 		}

	// 		require.NoError(jerr)
	// 		require.NotNil(job)
	// 		require.Equal("B", job.Id)
	// 	}
	// })

	t.Run("basic assignment with two", func(t *testing.T) {
		require := require.New(t)
		ctx := context.Background()

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create two builds slightly apart
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))
		time.Sleep(1 * time.Millisecond)
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "B",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get build A then B
		{
			job, err := s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
			require.NoError(err)
			require.NotNil(job)
			require.Equal("A", job.Id)
			_, err = s.JobAck(job.Id, true)
			require.NoError(err)
			require.NoError(s.JobComplete(job.Id, nil, nil))
		}
		{
			job, err := s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
			require.NoError(err)
			require.NotNil(job)
			require.Equal("B", job.Id)
			_, err = s.JobAck(job.Id, true)
			require.NoError(err)
			require.NoError(s.JobComplete(job.Id, nil, nil))
		}
	})

	t.Run("assignment by ID", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})
		testRunner(t, s, &vagrant_server.Runner{Id: "R_B"})

		// Create a build by ID
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Id{
					Id: &vagrant_server.Ref_RunnerId{
						Id: "R_A",
					},
				},
			},
		})))
		time.Sleep(1 * time.Millisecond)
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "B",
		})))
		time.Sleep(1 * time.Millisecond)
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "C",
		})))

		// Assign for R_B, which should get B since it won't match the earlier
		// assignment target.
		{
			job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_B"})
			require.NoError(err)
			require.NotNil(job)
			require.Equal("B", job.Id)
			_, err = s.JobAck(job.Id, true)
			require.NoError(err)
			require.NoError(s.JobComplete(job.Id, nil, nil))
		}

		// Assign for R_A, which should get A since it matches the target.
		{
			job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
			require.NoError(err)
			require.NotNil(job)
			require.Equal("A", job.Id)
			_, err = s.JobAck(job.Id, true)
			require.NoError(err)
			require.NoError(s.JobComplete(job.Id, nil, nil))
		}
	})

	t.Run("assignment by ID no candidates", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_B"})
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build by ID
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Id{
					Id: &vagrant_server.Ref_RunnerId{
						Id: "R_B",
					},
				},
			},
		})))

		// Assign for R_A which should get nothing cause it doesn't match.
		// NOTE that using "R_A" here is very important. This fixes a bug
		// where our lower bound was picking up invalid IDs.
		{
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()
			doneCh := make(chan struct{})
			go func() {
				defer close(doneCh)
				s.JobAssignForRunner(ctx, &vagrant_server.Runner{Id: "R_A"})
			}()

			// We should be blocking
			select {
			case <-doneCh:
				t.Fatal("should wait")

			case <-time.After(500 * time.Millisecond):
			}
		}
	})

	t.Run("any cannot be assigned to ByIdOnly runner", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)

		r := &vagrant_server.Runner{Id: "R_A", ByIdOnly: true}
		testRunner(t, s, r)

		// Create a build
		require.NoError(s.JobCreate(serverptypes.TestJobNew(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Should block because none direct assign
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		job, err := s.JobAssignForRunner(ctx, r)
		require.Error(err)
		require.Nil(job)
		require.Equal(ctx.Err(), err)

		// Create a target
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "B",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Id{
					Id: &vagrant_server.Ref_RunnerId{
						Id: "R_A",
					},
				},
			},
		})))

		// Assign it, we should get this build
		job, err = s.JobAssignForRunner(context.Background(), r)
		require.NoError(err)
		require.NotNil(job)
		require.Equal("B", job.Id)
	})
}

func TestJobAck(t *testing.T) {
	t.Run("ack", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		// Verify it is changed
		job, err = s.JobById(job.Id, nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_RUNNING, job.Job.State)

		// We should have an output buffer
		require.NotNil(job.OutputBuffer)
	})

	t.Run("ack negative", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)

		// Ack it
		_, err = s.JobAck(job.Id, false)
		require.NoError(err)

		// Verify it is changed
		job, err = s.JobById(job.Id, nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_QUEUED, job.State)

		// We should not have an output buffer
		require.Nil(job.OutputBuffer)
	})

	t.Run("timeout before ack should requeue", func(t *testing.T) {
		require := require.New(t)

		// Set a short timeout
		old := jobWaitingTimeout
		defer func() { jobWaitingTimeout = old }()
		jobWaitingTimeout = 5 * time.Millisecond

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)

		// Sleep too long
		time.Sleep(100 * time.Millisecond)

		// Verify it is queued
		job, err = s.JobById(job.Id, nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_QUEUED, job.Job.State)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.Error(err)
	})
}

func TestJobComplete(t *testing.T) {
	t.Run("success", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		// Complete it
		require.NoError(s.JobComplete(job.Id, &vagrant_server.Job_Result{
			Run: &vagrant_server.Job_CommandResult{},
		}, nil))

		// Verify it is changed
		job, err = s.JobById(job.Id, nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_SUCCESS, job.State)
		require.Nil(job.Error)
		require.NotNil(job.Result)
		require.NotNil(job.Result.Run)
	})

	t.Run("error", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		// Complete it
		require.NoError(s.JobComplete(job.Id, nil, fmt.Errorf("bad")))

		// Verify it is changed
		job, err = s.JobById(job.Id, nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_ERROR, job.State)
		require.NotNil(job.Error)

		st := status.FromProto(job.Error)
		require.Equal(codes.Unknown, st.Code())
		require.Contains(st.Message(), "bad")
	})
}

func TestJobIsAssignable(t *testing.T) {
	t.Run("no runners", func(t *testing.T) {
		require := require.New(t)
		ctx := context.Background()

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)

		// Create a build
		result, err := s.JobIsAssignable(ctx, testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		}))
		require.NoError(err)
		require.False(result)
	})

	t.Run("any target, runners exist", func(t *testing.T) {
		require := require.New(t)
		ctx := context.Background()

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Should be assignable
		result, err := s.JobIsAssignable(ctx, testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Any{
					Any: &vagrant_server.Ref_RunnerAny{},
				},
			},
		}))
		require.NoError(err)
		require.True(result)
	})

	t.Run("any target, runners ByIdOnly", func(t *testing.T) {
		require := require.New(t)
		ctx := context.Background()

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A", ByIdOnly: true})

		// Should be assignable
		result, err := s.JobIsAssignable(ctx, testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Any{
					Any: &vagrant_server.Ref_RunnerAny{},
				},
			},
		}))
		require.NoError(err)
		require.False(result)
	})

	t.Run("ID target, no match", func(t *testing.T) {
		require := require.New(t)
		ctx := context.Background()

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_B"})

		// Should be assignable
		result, err := s.JobIsAssignable(ctx, testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Id{
					Id: &vagrant_server.Ref_RunnerId{
						Id: "R_A",
					},
				},
			},
		}))
		require.NoError(err)
		require.False(result)
	})

	t.Run("ID target, match", func(t *testing.T) {
		require := require.New(t)
		ctx := context.Background()

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Should be assignable
		result, err := s.JobIsAssignable(ctx, testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Id{
					Id: &vagrant_server.Ref_RunnerId{
						Id: "R_A",
					},
				},
			},
		}))
		require.NoError(err)
		require.True(result)
	})
}

func TestJobCancel(t *testing.T) {
	t.Run("queued", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Cancel it
		require.NoError(s.JobCancel("A", false))

		// Verify it is canceled
		job, err := s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_ERROR, job.Job.State)
		require.NotNil(job.Job.Error)
		require.NotEmpty(job.CancelTime)
	})

	t.Run("assigned", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Cancel it
		require.NoError(s.JobCancel("A", false))

		// Verify it is canceled
		job, err = s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_WAITING, job.Job.State)
		require.NotEmpty(job.CancelTime)
	})

	t.Run("assigned with force", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Cancel it
		require.NoError(s.JobCancel("A", true))

		// Verify it is canceled
		job, err = s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_ERROR, job.Job.State)
		require.NotEmpty(job.CancelTime)
	})

	t.Run("assigned with force clears assignedSet", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			Operation: &vagrant_server.Job_Command{},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Cancel it
		require.NoError(s.JobCancel("A", true))

		// Verify it is canceled
		job, err = s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_ERROR, job.Job.State)
		require.NotEmpty(job.CancelTime)

		// Create a another job
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "B",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
			Operation: &vagrant_server.Job_Command{},
		})))

		ws := memdb.NewWatchSet()

		// Read it back to check the blocked status
		job2, err := s.JobById("B", ws)
		require.NoError(err)
		require.NotNil(job2)
		require.Equal("B", job2.Id)
		require.Equal(vagrant_server.Job_QUEUED, job2.State)
		require.False(job2.Blocked)
	})

	t.Run("completed", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		// Complete it
		require.NoError(s.JobComplete(job.Id, nil, nil))

		// Cancel it
		require.NoError(s.JobCancel("A", false))

		// Verify it is not canceled
		job, err = s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_SUCCESS, job.Job.State)
		require.Empty(job.CancelTime)
	})
}

func TestJobHeartbeat(t *testing.T) {
	t.Run("times out after ack", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Set a short timeout
		old := jobHeartbeatTimeout
		defer func() { jobHeartbeatTimeout = old }()
		jobHeartbeatTimeout = 5 * time.Millisecond

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		time.Sleep(1 * time.Second)

		// Should time out
		require.Eventually(func() bool {
			// Verify it is canceled
			job, err = s.JobById("A", nil)
			require.NoError(err)
			return job.Job.State == vagrant_server.Job_ERROR
		}, 1*time.Second, 10*time.Millisecond)
	})

	t.Run("doesn't time out if heartbeating", func(t *testing.T) {
		require := require.New(t)

		// Set a short timeout
		old := jobHeartbeatTimeout
		defer func() { jobHeartbeatTimeout = old }()
		jobHeartbeatTimeout = 250 * time.Millisecond

		s := TestState(t)
		defer s.Close()
		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		// Start heartbeating
		ctx, cancel := context.WithCancel(context.Background())
		doneCh := make(chan struct{})
		defer func() {
			cancel()
			<-doneCh
		}()
		go func() {
			defer close(doneCh)

			tick := time.NewTicker(20 * time.Millisecond)
			defer tick.Stop()

			for {
				select {
				case <-tick.C:
					s.JobHeartbeat(job.Id)

				case <-ctx.Done():
					return
				}
			}
		}()

		// Sleep for a bit
		time.Sleep(1 * time.Second)

		// Verify it is running
		job, err = s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_RUNNING, job.Job.State)

		// Stop it
		require.NoError(s.JobComplete(job.Id, nil, nil))
	})

	t.Run("times out if heartbeating stops", func(t *testing.T) {
		require := require.New(t)

		// Set a short timeout
		old := jobHeartbeatTimeout
		defer func() { jobHeartbeatTimeout = old }()
		jobHeartbeatTimeout = 250 * time.Millisecond

		s := TestState(t)
		defer s.Close()

		projRef := testProject(t, s)
		testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

		// Create a build
		require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
			Id: "A",
			Scope: &vagrant_server.Job_Project{
				Project: projRef,
			},
		})))

		// Assign it, we should get this build
		job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
		require.NoError(err)
		require.NotNil(job)
		require.Equal("A", job.Id)
		require.Equal(vagrant_server.Job_WAITING, job.State)

		// Ack it
		_, err = s.JobAck(job.Id, true)
		require.NoError(err)

		// Start heartbeating
		ctx, cancel := context.WithCancel(context.Background())
		doneCh := make(chan struct{})
		defer func() {
			cancel()
			<-doneCh
		}()
		go func() {
			defer close(doneCh)

			tick := time.NewTicker(20 * time.Millisecond)
			defer tick.Stop()

			for {
				select {
				case <-tick.C:
					s.JobHeartbeat(job.Id)

				case <-ctx.Done():
					return
				}
			}
		}()

		// Sleep for a bit
		time.Sleep(10 * time.Millisecond)

		// Verify it is running
		job, err = s.JobById("A", nil)
		require.NoError(err)
		require.Equal(vagrant_server.Job_RUNNING, job.Job.State)

		// Stop heartbeating
		cancel()

		// Pause before check. We encounter the database being
		// scrubbed otherwise (TODO: fixme)
		time.Sleep(1 * time.Second)

		// Should time out
		require.Eventually(func() bool {
			// Verify it is canceled
			job, err = s.JobById("A", nil)
			require.NoError(err)
			return job.Job.State == vagrant_server.Job_ERROR
		}, 1*time.Second, 10*time.Millisecond)
	})

	// t.Run("times out if running state loaded on restart", func(t *testing.T) {
	// 	require := require.New(t)

	// 	// Set a short timeout
	// 	old := jobHeartbeatTimeout
	// 	defer func() { jobHeartbeatTimeout = old }()
	// 	jobHeartbeatTimeout = 250 * time.Millisecond

	// 	s := TestState(t)
	// 	defer s.Close()
	// 	projRef := testProject(t, s)
	// 	testRunner(t, s, &vagrant_server.Runner{Id: "R_A"})

	// 	// Create a build
	// 	require.NoError(s.JobCreate(testJob(t, &vagrant_server.Job{
	// 		Id: "A",
	// 		Scope: &vagrant_server.Job_Project{
	// 			Project: projRef,
	// 		},
	// 	})))

	// 	// Assign it, we should get this build
	// 	job, err := s.JobAssignForRunner(context.Background(), &vagrant_server.Runner{Id: "R_A"})
	// 	require.NoError(err)
	// 	require.NotNil(job)
	// 	require.Equal("A", job.Id)
	// 	require.Equal(vagrant_server.Job_WAITING, job.State)

	// 	// Ack it
	// 	_, err = s.JobAck(job.Id, true)
	// 	require.NoError(err)

	// 	// Start heartbeating
	// 	ctx, cancel := context.WithCancel(context.Background())
	// 	doneCh := make(chan struct{})
	// 	defer func() {
	// 		cancel()
	// 		<-doneCh
	// 	}()
	// 	go func(s *State) {
	// 		defer close(doneCh)

	// 		tick := time.NewTicker(20 * time.Millisecond)
	// 		defer tick.Stop()

	// 		for {
	// 			select {
	// 			case <-tick.C:
	// 				s.JobHeartbeat(job.Id)

	// 			case <-ctx.Done():
	// 				return
	// 			}
	// 		}
	// 	}(s)

	// 	Reinit the state as if we crashed
	// 	s = TestStateReinit(t, s)
	// 	defer s.Close()

	// 	// Verify it exists
	// 	job, err = s.JobById("A", nil)
	// 	require.NoError(err)
	// 	require.Equal(vagrant_server.Job_RUNNING, job.Job.State)

	// 	// Should time out
	// 	require.Eventually(func() bool {
	// 		// Verify it is canceled
	// 		job, err = s.JobById("A", nil)
	// 		require.NoError(err)
	// 		return job.Job.State == vagrant_server.Job_ERROR
	// 	}, 2*time.Second, 10*time.Millisecond)
	// })
}
