// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package runner

import (
	"context"
	"io"
	"path/filepath"
	"sync"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var heartbeatDuration = 5 * time.Second

// Accept will accept and execute a single job. This will block until
// a job is available.
//
// An error is only returned if there was an error internal to the runner.
// Errors during job execution are expected (i.e. a project build is misconfigured)
// and will be reported on the job.
//
// This is safe to be called concurrently which can be used to execute
// multiple jobs in parallel as a runner.
func (r *Runner) Accept(ctx context.Context) error {
	return r.accept(ctx, "")
}

// AcceptExact is the same as Accept except that it accepts only
// a job with exactly the given ID. This is used by Vagrant only in
// local execution mode as an extra security measure to prevent other
// jobs from being assigned to the runner.
func (r *Runner) AcceptExact(ctx context.Context, id string) error {
	return r.accept(ctx, id)
}

func (r *Runner) accept(ctx context.Context, id string) error {
	if r.closed() {
		return ErrClosed
	}

	log := r.logger

	// Open a new job stream. NOTE: we purposely do NOT use ctx above
	// since if the context is cancelled we want to continue reporting
	// errors.
	log.Debug("opening job stream")
	client, err := r.client.RunnerJobStream(context.Background())
	if err != nil {
		return err
	}
	defer client.CloseSend()

	// Send our request
	log.Trace("sending job request")
	if err := client.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Request_{
			Request: &vagrant_server.RunnerJobStreamRequest_Request{
				RunnerId: r.id,
			},
		},
	}); err != nil {
		return err
	}

	// Wait for an assignment
	log.Info("waiting for job assignment")
	resp, err := client.Recv()
	if err != nil {
		return err
	}

	// We received an assignment!
	assignment, ok := resp.Event.(*vagrant_server.RunnerJobStreamResponse_Assignment)
	if !ok {
		return status.Errorf(codes.Aborted,
			"expected job assignment, server sent %T",
			resp.Event)
	}
	log = log.With("job_id", assignment.Assignment.Job.Id)
	log.Info("job assignment received")

	// We increment the waitgroup at this point since prior to this if we're
	// forcefully quit, we shouldn't have acked. This is somewhat brittle so
	// a todo here is to build a better notification mechanism that we've quit
	// and exit here.
	r.acceptWg.Add(1)
	defer r.acceptWg.Done()

	// If this isn't the job we expected then we nack and error.
	if id != "" {
		if assignment.Assignment.Job.Id != id {
			log.Warn("unexpected job id for exact match, nacking")
			if err := client.Send(&vagrant_server.RunnerJobStreamRequest{
				Event: &vagrant_server.RunnerJobStreamRequest_Error_{
					Error: &vagrant_server.RunnerJobStreamRequest_Error{},
				},
			}); err != nil {
				return err
			}

			return status.Errorf(codes.Aborted, "server sent us an invalid job")
		}

		log.Trace("assigned job matches expected ID for local mode")
	}

	// Ack the assignment
	log.Trace("acking job assignment")
	if err := client.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Ack_{
			Ack: &vagrant_server.RunnerJobStreamRequest_Ack{},
		},
	}); err != nil {
		return err
	}

	// Create a cancelable context so we can stop if job is canceled
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	// We need a mutex to protect against simultaneous sends to the client.
	var sendMutex sync.Mutex

	// For our UI, we always send output to the server. If we have a local UI
	// set, we mirror to that as well.
	var ui terminal.UI = &runnerUI{
		ctx:    ctx,
		cancel: cancel,
		evc:    client,
		mu:     &sendMutex,
	}
	if r.ui != nil {
		ui = &multiUI{
			UIs: []terminal.UI{r.ui, ui},
		}
	}

	// Start up a goroutine to listen for any other events
	errCh := make(chan error, 1)
	go func() {
		for {
			// Wait for the connection to close. We do this because this ensures
			// that the server received our completion and updated the database.
			resp, err = client.Recv()
			if err != nil {
				errCh <- err
				return
			}

			// Determine the event
			switch resp.Event.(type) {
			case *vagrant_server.RunnerJobStreamResponse_Cancel:
				log.Info("job cancellation request received, canceling")
				cancel()

			default:
				log.Info("unknown job event", "event", resp.Event)
			}
		}
	}()

	// Heartbeat
	go func() {
		tick := time.NewTicker(heartbeatDuration)
		defer tick.Stop()

		for {
			select {
			case <-ctx.Done():
				return

			case <-tick.C:
			}

			sendMutex.Lock()
			err := client.Send(&vagrant_server.RunnerJobStreamRequest{
				Event: &vagrant_server.RunnerJobStreamRequest_Heartbeat_{
					Heartbeat: &vagrant_server.RunnerJobStreamRequest_Heartbeat{},
				},
			})
			sendMutex.Unlock()
			if err != nil && err != io.EOF {
				log.Warn("error during heartbeat", "err", err)
			}
		}
	}()

	// We need to get our data source next prior to executing.
	var result *vagrant_server.Job_Result
	wd, closer, err := r.downloadJobData(
		ctx,
		log,
		ui,
		assignment.Assignment.Job.DataSource,
		assignment.Assignment.Job.DataSourceOverrides,
	)
	if err == nil {
		log.Debug("job data downloaded (or local)", "pwd", wd)

		if closer != nil {
			defer func() {
				log.Debug("cleaning up downloaded data")
				if err := closer(); err != nil {
					log.Warn("error cleaning up data", "err", err)
				}
			}()
		}

		// We want the working directory to always be absolute.
		if !filepath.IsAbs(wd) {
			err = status.Errorf(codes.Internal,
				"data working directory should be absolute. This is a bug, please report it.")
		}

		if err == nil {
			// Execute the job. We have to close the UI right afterwards to
			// ensure that no more output is writting to the client.
			log.Info("starting job execution")
			result, err = r.executeJob(ctx, log, ui, assignment.Assignment.Job, wd)
			if ui, ok := ui.(io.Closer); ok {
				ui.Close()
			}
			log.Debug("job finished", "error", err)
		}
	}

	// Check if we were force canceled. If so, then just exit now. Realistically
	// we could also be force cancelled at any point below but this is the
	// most likely spot to catch it and the error scenario below is not bad.
	if ctx.Err() != nil {
		select {
		case err := <-errCh:
			// If we got an EOF then we were force cancelled.
			if err == io.EOF {
				log.Info("job force canceled")
				return nil
			}
		default:
		}
	}

	// For the remainder of the job, we're going to hold the mutex. We are
	// just sending quick status updates so this should not block anything
	// for very long.
	sendMutex.Lock()
	defer sendMutex.Unlock()

	// Handle job execution errors
	if err != nil {
		st, _ := status.FromError(err)

		log.Warn("error during job execution", "err", err)
		if rpcerr := client.Send(&vagrant_server.RunnerJobStreamRequest{
			Event: &vagrant_server.RunnerJobStreamRequest_Error_{
				Error: &vagrant_server.RunnerJobStreamRequest_Error{
					Error: st.Proto(),
				},
			},
		}); rpcerr != nil {
			log.Warn("error sending error event, job may be dangling", "err", rpcerr)
		}

		return nil
	}

	// Complete the job
	log.Debug("sending job completion")
	if err := client.Send(&vagrant_server.RunnerJobStreamRequest{
		Event: &vagrant_server.RunnerJobStreamRequest_Complete_{
			Complete: &vagrant_server.RunnerJobStreamRequest_Complete{
				Result: result,
			},
		},
	}); err != nil {
		log.Error("error sending job complete message", "error", err)
		return err
	}

	// Wait for the connection to close. We do this because this ensures
	// that the server received our completion and updated the database.
	err = <-errCh
	if err == io.EOF {
		return nil
	}

	return err
}
