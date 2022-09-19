package singleprocess

import (
	"context"
	"time"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-memdb"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/logbuffer"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
	"github.com/hashicorp/vagrant/internal/server/singleprocess/state"
)

const (
	maximumJobsIndexed = 50
)

func (s *service) PruneOldJobs(
	ctx context.Context,
	_ *emptypb.Empty,
) (*emptypb.Empty, error) {
	_, err := s.state.JobsDBPruneOld(maximumJobsIndexed)
	return &emptypb.Empty{}, err
}

// TODO: test
func (s *service) GetJob(
	ctx context.Context,
	req *vagrant_server.GetJobRequest,
) (*vagrant_server.Job, error) {
	job, err := s.state.JobById(req.JobId, nil)
	if err != nil {
		return nil, err
	}
	if job == nil || job.Job == nil {
		return nil, status.Errorf(codes.NotFound, "job not found")
	}

	return job.Job, nil
}

// TODO: test
func (s *service) XListJobs(
	ctx context.Context,
	req *vagrant_server.ListJobsRequest,
) (*vagrant_server.ListJobsResponse, error) {
	jobs, err := s.state.JobList()
	if err != nil {
		return nil, err
	}

	return &vagrant_server.ListJobsResponse{
		Jobs: jobs,
	}, nil
}

func (s *service) CancelJob(
	ctx context.Context,
	req *vagrant_server.CancelJobRequest,
) (*emptypb.Empty, error) {
	if err := s.state.JobCancel(req.JobId, false); err != nil {
		return nil, err
	}

	return &emptypb.Empty{}, nil
}

func (s *service) QueueJob(
	ctx context.Context,
	req *vagrant_server.QueueJobRequest,
) (*vagrant_server.QueueJobResponse, error) {
	job := req.Job

	// Validation
	if job == nil {
		return nil, status.Errorf(codes.FailedPrecondition, "job must be set")
	}

	// Get the next id
	id, err := server.Id()
	if err != nil {
		return nil, status.Errorf(codes.Internal, "uuid generation failed: %s", err)
	}
	job.Id = id

	// Validate expiry if we have one
	job.ExpireTime = nil
	if req.ExpiresIn != "" {
		dur, err := time.ParseDuration(req.ExpiresIn)
		if err != nil {
			return nil, status.Errorf(codes.FailedPrecondition,
				"Invalid expiry duration: %s", err.Error())
		}

		job.ExpireTime = timestamppb.New(time.Now().Add(dur))
	}

	// Queue the job
	if err := s.state.JobCreate(job); err != nil {
		return nil, err
	}

	return &vagrant_server.QueueJobResponse{JobId: job.Id}, nil
}

func (s *service) ValidateJob(
	ctx context.Context,
	req *vagrant_server.ValidateJobRequest,
) (*vagrant_server.ValidateJobResponse, error) {
	var err error
	result := &vagrant_server.ValidateJobResponse{Valid: true}

	// Struct validation
	if err := serverptypes.ValidateJob(req.Job); err != nil {
		result.Valid = false
		result.ValidationError = status.New(codes.FailedPrecondition, err.Error()).Proto()
		return result, nil
	}

	// Check assignability
	result.Assignable, err = s.state.JobIsAssignable(ctx, req.Job)
	if err != nil {
		return nil, err
	}

	return result, nil
}

func (s *service) GetJobStream(
	req *vagrant_server.GetJobStreamRequest,
	server vagrant_server.Vagrant_GetJobStreamServer,
) error {
	log := hclog.FromContext(server.Context())
	ctx := server.Context()

	// Get the job
	ws := memdb.NewWatchSet()
	job, err := s.state.JobById(req.JobId, ws)
	if err != nil {
		return err
	}
	if job == nil {
		return status.Errorf(codes.NotFound, "job not found for ID: %s", req.JobId)
	}
	log = log.With("job_id", job.Id)

	// We always send the open message as confirmation the job was found.
	if err := server.Send(&vagrant_server.GetJobStreamResponse{
		Event: &vagrant_server.GetJobStreamResponse_Open_{
			Open: &vagrant_server.GetJobStreamResponse_Open{},
		},
	}); err != nil {
		return err
	}

	// Start a goroutine that watches for job changes
	jobCh := make(chan *state.Job, 1)
	errCh := make(chan error, 1)
	go func() {
		for {
			// Send the job
			select {
			case jobCh <- job:
			case <-ctx.Done():
				return
			}

			// Wait for the job to update
			if err := ws.WatchCtx(ctx); err != nil {
				if ctx.Err() == nil {
					errCh <- err
				}

				return
			}

			// Updated job, requery it
			ws = memdb.NewWatchSet()
			job, err = s.state.JobById(job.Id, ws)
			if err != nil {
				errCh <- err
				return
			}
			if job == nil {
				errCh <- status.Errorf(codes.Internal, "job disappeared for ID: %s", req.JobId)
				return
			}
		}
	}()

	// Enter the event loop
	var lastState vagrant_server.Job_State
	var cancelSent bool
	var eventsCh <-chan []*vagrant_server.GetJobStreamResponse_Terminal_Event
	for {
		select {
		case <-ctx.Done():
			return nil

		case err := <-errCh:
			return err

		case job := <-jobCh:
			log.Debug("job state change", "state", job.State)

			// If we have a state change, send that event down. We also send
			// down a state change if we enter a "cancelled" scenario.
			canceling := job.CancelTime != nil
			if lastState != job.State || cancelSent != canceling {
				if err := server.Send(&vagrant_server.GetJobStreamResponse{
					Event: &vagrant_server.GetJobStreamResponse_State_{
						State: &vagrant_server.GetJobStreamResponse_State{
							Previous:  lastState,
							Current:   job.State,
							Job:       job.Job,
							Canceling: canceling,
						},
					},
				}); err != nil {
					return err
				}

				lastState = job.State
				cancelSent = canceling
			}

			// If we haven't initialized output streaming and the output buffer
			// is now non-nil, initialize that. This will send any buffered
			// data down.
			if eventsCh == nil && job.OutputBuffer != nil {
				eventsCh, err = s.getJobStreamOutputInit(ctx, job, server)
				if err != nil {
					return err
				}
			}

			switch job.State {
			case vagrant_server.Job_SUCCESS, vagrant_server.Job_ERROR:
				// TODO(mitchellh): we should drain the output buffer

				// Job is done. For success, error will be nil, so this
				// populates the event with the proper values.
				return server.Send(&vagrant_server.GetJobStreamResponse{
					Event: &vagrant_server.GetJobStreamResponse_Complete_{
						Complete: &vagrant_server.GetJobStreamResponse_Complete{
							Error:  job.Error,
							Result: job.Result,
						},
					},
				})
			}

		case events := <-eventsCh:
			if err := server.Send(&vagrant_server.GetJobStreamResponse{
				Event: &vagrant_server.GetJobStreamResponse_Terminal_{
					Terminal: &vagrant_server.GetJobStreamResponse_Terminal{
						Events: events,
					},
				},
			}); err != nil {
				return err
			}
		}
	}
}

func (s *service) readJobLogBatch(r *logbuffer.Reader, block bool) []*vagrant_server.GetJobStreamResponse_Terminal_Event {
	entries := r.Read(64, block)
	if entries == nil {
		return nil
	}

	events := make([]*vagrant_server.GetJobStreamResponse_Terminal_Event, len(entries))
	for i, entry := range entries {
		events[i] = entry.(*vagrant_server.GetJobStreamResponse_Terminal_Event)
	}

	return events
}

func (s *service) getJobStreamOutputInit(
	ctx context.Context,
	job *state.Job,
	server vagrant_server.Vagrant_GetJobStreamServer,
) (<-chan []*vagrant_server.GetJobStreamResponse_Terminal_Event, error) {
	// Send down all our buffered lines.
	outputR := job.OutputBuffer.Reader(-1)
	go outputR.CloseContext(ctx)
	for {
		events := s.readJobLogBatch(outputR, false)
		if events == nil {
			break
		}

		if err := server.Send(&vagrant_server.GetJobStreamResponse{
			Event: &vagrant_server.GetJobStreamResponse_Terminal_{
				Terminal: &vagrant_server.GetJobStreamResponse_Terminal{
					Events:   events,
					Buffered: true,
				},
			},
		}); err != nil {
			return nil, err
		}
	}

	// Start a goroutine that reads output
	eventsCh := make(chan []*vagrant_server.GetJobStreamResponse_Terminal_Event, 1)
	go func() {
		for {
			events := s.readJobLogBatch(outputR, true)
			if events == nil {
				return
			}

			select {
			case eventsCh <- events:
			case <-ctx.Done():
				return
			}
		}
	}()

	return eventsCh, nil
}
