// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

import (
	"context"
	"io"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-memdb"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/server/logbuffer"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/server/singleprocess/state"
)

// TODO: test
func (s *service) GetRunner(
	ctx context.Context,
	req *vagrant_server.GetRunnerRequest,
) (*vagrant_server.Runner, error) {
	return s.state.RunnerById(req.RunnerId)
}

// TODO: test
func (s *service) RunnerConfig(
	srv vagrant_server.Vagrant_RunnerConfigServer,
) error {
	log := hclog.FromContext(srv.Context())
	ctx, cancel := context.WithCancel(srv.Context())
	defer cancel()

	// Get the request
	event, err := srv.Recv()
	if err != nil {
		return err
	}
	req, ok := event.Event.(*vagrant_server.RunnerConfigRequest_Open_)
	if !ok {
		return status.Errorf(codes.FailedPrecondition,
			"expected open event, got %T", event)
	}
	record := req.Open.Runner

	// Create our record
	log = log.With("runner_id", record.Id)
	log.Trace("registering runner")
	if err := s.state.RunnerCreate(record); err != nil {
		return err
	}

	// Defer deleting this.
	// TODO(mitchellh): this is too aggressive and we want to have some grace
	// period for reconnecting clients. We should clean this up.
	defer func() {
		log.Trace("deleting runner")
		if err := s.state.RunnerDelete(record.Id); err != nil {
			log.Error("failed to delete runner data. This should not happen.", "err", err)
		}
	}()

	// Start a goroutine that listens on the recvmsg so we can detect
	// when the client exited.
	go func() {
		defer cancel()

		for {
			_, err := srv.Recv()
			if err != nil {
				if err != io.EOF {
					log.Warn("unknown error from recvmsg", "err", err)
				}

				return
			}
		}
	}()

	// Build our config in a loop.
	for {
		ws := memdb.NewWatchSet()

		// Build our config
		config := &vagrant_server.RunnerConfig{}

		// Get our config vars
		vars, err := s.state.ConfigGetWatch(&vagrant_server.ConfigGetRequest{
			Scope: &vagrant_server.ConfigGetRequest_Runner{
				Runner: &vagrant_server.Ref_RunnerId{
					Id: record.Id,
				},
			},
		}, ws)
		if err != nil {
			return err
		}
		config.ConfigVars = vars

		// Send new config
		if err := srv.Send(&vagrant_server.RunnerConfigResponse{
			Config: config,
		}); err != nil {
			return err
		}

		// Nil out the stuff we used so that if we're waiting awhile we can GC
		config = nil

		// Wait for any changes
		if err := ws.WatchCtx(ctx); err != nil {
			return err
		}
	}
}

func (s *service) RunnerJobStream(
	server vagrant_server.Vagrant_RunnerJobStreamServer,
) error {
	log := hclog.FromContext(server.Context())
	ctx, cancel := context.WithCancel(server.Context())
	defer cancel()

	// Receive our opening message so we can determine the runner ID.
	req, err := server.Recv()
	if err != nil {
		return err
	}
	reqEvent, ok := req.Event.(*vagrant_server.RunnerJobStreamRequest_Request_)
	if !ok {
		return status.Errorf(codes.FailedPrecondition,
			"first message must be a Request event")
	}
	log = log.With("runner_id", reqEvent.Request.RunnerId)

	// Get the runner to validate it is registered
	runner, err := s.state.RunnerById(reqEvent.Request.RunnerId)
	if err != nil {
		return err
	}

	// Get a job assignment for this runner
	job, err := s.state.JobAssignForRunner(ctx, runner)
	if err != nil {
		return err
	}

	// Send the job assignment.
	//
	// If this has an error, we continue to accumulate the error until
	// we set the ack status in the DB. We do this because if we fail to
	// send the job assignment we want to nack the job so it is queued again.
	err = server.Send(&vagrant_server.RunnerJobStreamResponse{
		Event: &vagrant_server.RunnerJobStreamResponse_Assignment{
			Assignment: &vagrant_server.RunnerJobStreamResponse_JobAssignment{
				Job: job.Job,
			},
		},
	})

	// Wait for an ack. We only do this if the job assignment above
	// succeeded. If it didn't succeed, the client will never send us
	// an ack.
	ack := false
	if err == nil { // if sending the job assignment was a success
		req, err = server.Recv()

		// If we received a message we inspect it. If we failed to
		// receive a message, we've set the `err` value and we keep
		// ack to false so that we nack the job later.
		if err == nil {
			switch req.Event.(type) {
			case *vagrant_server.RunnerJobStreamRequest_Ack_:
				ack = true

			case *vagrant_server.RunnerJobStreamRequest_Error_:
				ack = false

			default:
				ack = false
				err = status.Errorf(codes.FailedPrecondition,
					"ack expected, got: %T", req.Event)
			}
		}
	}

	// Send the ack.
	job, ackerr := s.state.JobAck(job.Id, ack)
	if ackerr != nil {
		// If this fails, we just log, there is nothing more we can do.
		log.Warn("job ack failed", "outer_error", err, "error", ackerr)

		// If we had no outer error, set the ackerr so that we exit. If
		// we do have an outer error, then the ack error only shows up in
		// the log.
		if err == nil {
			err = ackerr
		}
	}

	// If we have an error, return that. We also return if we didn't ack for
	// any reason. This error can be set at any point since job assignment.
	if err != nil || !ack {
		return err
	}

	// Start a goroutine that watches for job changes
	jobCh := make(chan *state.Job, 1)
	errCh := make(chan error, 1)
	go func() {
		for {
			ws := memdb.NewWatchSet()
			job, err = s.state.JobById(job.Id, ws)
			if err != nil {
				errCh <- err
				return
			}
			if job == nil {
				errCh <- status.Errorf(codes.Internal, "job disappeared")
				return
			}

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
		}
	}()

	// Create a goroutine that just waits for events. We have to do this
	// so we can exit properly on client side close.
	eventCh := make(chan *vagrant_server.RunnerJobStreamRequest, 1)
	go func() {
		defer cancel()

		for {
			log.Trace("waiting for job stream event")
			req, err := server.Recv()
			if err == io.EOF {
				// On EOF, this means the client closed their write side.
				// In this case, we assume we have exited and exit accordingly.
				return
			}

			if err != nil {
				// For any other error, we send the error along and exit the
				// read loop. The sent error will be picked up and sent back
				// as a result to the client.
				errCh <- err
				return
			}
			log.Trace("event received", "event", req.Event)

			// Send the event down
			select {
			case eventCh <- req:
			case <-ctx.Done():
				return
			}

			// If this is a terminating event, we exit this loop
			switch event := req.Event.(type) {
			case *vagrant_server.RunnerJobStreamRequest_Complete_:
				log.Debug("job stream recv loop exiting due to completion")
				return
			case *vagrant_server.RunnerJobStreamRequest_Error_:
				log.Debug("job stream recv loop exiting due to error",
					"error", event.Error.Error.Message)
				return
			}
		}
	}()

	// Recv events in a loop
	var lastJob *vagrant_server.Job
	for {
		select {
		case <-ctx.Done():
			// We need to drain the event channel
			for {
				select {
				case req := <-eventCh:
					if err := s.handleJobStreamRequest(log, job, server, req); err != nil {
						return err
					}
				default:
					return nil
				}
			}

		case err := <-errCh:
			return err

		case req := <-eventCh:
			if err := s.handleJobStreamRequest(log, job, server, req); err != nil {
				return err
			}

		case job := <-jobCh:
			if lastJob == job.Job {
				continue
			}

			// If the job is canceled, send that event. We send this each time
			// the cancel time changes. The cancel time only changes if multiple
			// cancel requests are made.
			if job.CancelTime != nil &&
				(lastJob == nil || lastJob.CancelTime != job.CancelTime) {
				// The job is forced if we're in an error state. This must be true
				// because we would've already exited the loop if we naturally
				// got a terminal event.
				force := job.State == vagrant_server.Job_ERROR

				err := server.Send(&vagrant_server.RunnerJobStreamResponse{
					Event: &vagrant_server.RunnerJobStreamResponse_Cancel{
						Cancel: &vagrant_server.RunnerJobStreamResponse_JobCancel{
							Force: force,
						},
					},
				})
				if err != nil {
					return err
				}

				// On force we exit immediately.
				if force {
					return nil
				}
			}

			lastJob = job.Job
		}
	}
}

func (s *service) handleJobStreamRequest(
	log hclog.Logger,
	job *state.Job,
	srv vagrant_server.Vagrant_RunnerJobStreamServer,
	req *vagrant_server.RunnerJobStreamRequest,
) error {
	log.Trace("event received", "event", req.Event)
	switch event := req.Event.(type) {
	case *vagrant_server.RunnerJobStreamRequest_Complete_:
		return s.state.JobComplete(job.Id, event.Complete.Result, nil)

	case *vagrant_server.RunnerJobStreamRequest_Error_:
		return s.state.JobComplete(job.Id, nil, status.FromProto(event.Error.Error).Err())

	case *vagrant_server.RunnerJobStreamRequest_Heartbeat_:
		return s.state.JobHeartbeat(job.Id)

	case *vagrant_server.RunnerJobStreamRequest_Terminal:
		// This shouldn't happen but we want to protect against it to prevent
		// a panic.
		if job.OutputBuffer == nil {
			log.Warn("got terminal event but internal output buffer is nil, dropping lines")
			return nil
		}

		// Write the entries to the output buffer
		entries := make([]logbuffer.Entry, len(event.Terminal.Events))
		for i, ev := range event.Terminal.Events {
			entries[i] = ev
		}

		// Write the events
		job.OutputBuffer.Write(entries...)

		return nil

	default:
		log.Warn("unexpected event received", "event", req.Event)
	}

	return nil
}
