// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package client

import (
	"context"
	"fmt"
	"io"
	"time"

	"github.com/hashicorp/go-hclog"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/pkg/finalcontext"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type JobModifier func(*vagrant_server.Job)

// job returns the basic job skeleton prepoulated with the correct
// defaults based on how the client is configured. For example, for local
// operations, this will already have the targeting for the local runner.
func (c *Client) job() *vagrant_server.Job {
	job := &vagrant_server.Job{
		TargetRunner: c.runnerRef,

		DataSource: &vagrant_server.Job_DataSource{
			Source: &vagrant_server.Job_DataSource_Local{
				Local: &vagrant_server.Job_Local{},
			},
		},

		Operation: &vagrant_server.Job_Noop_{
			Noop: &vagrant_server.Job_Noop{},
		},
	}

	return job
}

// doJob will queue and execute the job. If the client is configured for
// local mode, this will start and target the proper runner.
func (c *Client) doJob(
	ctx context.Context,
	job *vagrant_server.Job,
	ui terminal.UI,
) (*vagrant_server.Job_Result, error) {
	log := c.logger

	if ui == nil {
		ui = c.ui
	}

	// cb is used in local mode only to get a callback of the job ID
	// so we can tell our runner what ID to expect.
	var cb func(string)

	// In local mode we need to setup our callback
	if c.localRunner {
		var jobCh chan struct{}

		defer func() {
			if jobCh != nil {
				log.Info("waiting for accept to finish")
				<-jobCh
				log.Debug("finished waiting for job accept")
			}
		}()

		// Set our callback up so that we will accept a job once it is queued
		// so that we can accept exactly this job.
		cb = func(id string) {
			jobCh = make(chan struct{})
			go func() {
				defer close(jobCh)
				if err := c.runner.AcceptExact(ctx, id); err != nil {
					log.Error("runner job accept error", "err", err)
				}
			}()
		}
	}

	return c.queueAndStreamJob(ctx, job, ui, cb)
}

// queueAndStreamJob will queue the job. If the client is configured to watch the job,
// it'll also stream the output to the configured UI.
func (c *Client) queueAndStreamJob(
	ctx context.Context,
	job *vagrant_server.Job,
	ui terminal.UI,
	jobIdCallback func(string),
) (*vagrant_server.Job_Result, error) {
	log := c.logger

	// When local, we set an expiration here in case we can't gracefully
	// cancel in the event of an error. This will ensure that the jobs don't
	// remain queued forever. This is only for local ops.
	expiration := ""
	if c.localRunner {
		expiration = "30s"
	}

	// Queue the job
	log.Debug("queueing job", "operation", fmt.Sprintf("%T", job.Operation))
	queueResp, err := c.client.QueueJob(ctx, &vagrant_server.QueueJobRequest{
		Job:       job,
		ExpiresIn: expiration,
	})
	if err != nil {
		return nil, err
	}
	log = log.With("job_id", queueResp.JobId)

	// Call our callback if it was given
	if jobIdCallback != nil {
		jobIdCallback(queueResp.JobId)
	}

	// Get the stream
	log.Debug("opening job stream")
	stream, err := c.client.GetJobStream(ctx, &vagrant_server.GetJobStreamRequest{
		JobId: queueResp.JobId,
	})
	if err != nil {
		return nil, err
	}

	// Wait for open confirmation
	resp, err := stream.Recv()
	if err != nil {
		return nil, err
	}
	if _, ok := resp.Event.(*vagrant_server.GetJobStreamResponse_Open_); !ok {
		return nil, status.Errorf(codes.Aborted,
			"job stream failed to open, got unexpected message %T",
			resp.Event)
	}

	type stepData struct {
		terminal.Step

		out io.Writer
	}

	// Process events
	var (
		completed bool

		stateEventTimer *time.Timer
		tstatus         terminal.Status

		stdout, stderr io.Writer

		sg    terminal.StepGroup
		steps = map[int32]*stepData{}
	)

	if c.localRunner {
		defer func() {
			// If we completed then do nothing, or if the context is still
			// active since this means that we're not cancelled.
			if completed || ctx.Err() == nil {
				return
			}

			ctx, cancel := finalcontext.Context(log)
			defer cancel()

			log.Warn("canceling job")
			_, err := c.client.CancelJob(ctx, &vagrant_server.CancelJobRequest{
				JobId: queueResp.JobId,
			})
			if err != nil {
				log.Warn("error canceling job", "err", err)
			} else {
				log.Info("job cancelled successfully")
			}
		}()
	}

	for {
		resp, err := stream.Recv()
		if err != nil {
			return nil, err
		}
		if resp == nil {
			// This shouldn't happen, but if it does, just ignore it.
			log.Warn("nil response received, ignoring")
			continue
		}

		switch event := resp.Event.(type) {
		case *vagrant_server.GetJobStreamResponse_Complete_:
			completed = true

			if event.Complete.Error == nil {
				log.Info("job completed successfully")
				return event.Complete.Result, nil
			}

			st := status.FromProto(event.Complete.Error)
			log.Warn("job failed", "code", st.Code(), "message", st.Message())
			return nil, st.Err()

		case *vagrant_server.GetJobStreamResponse_Error_:
			completed = true

			st := status.FromProto(event.Error.Error)
			log.Warn("job stream failure", "code", st.Code(), "message", st.Message())
			return nil, st.Err()

		case *vagrant_server.GetJobStreamResponse_Terminal_:
			// Ignore this for local jobs since we're using our UI directly.
			if c.localRunner {
				continue
			}

			for _, ev := range event.Terminal.Events {
				log.Trace("job terminal output", "event", ev)

				switch ev := ev.Event.(type) {
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_Line_:
					ui.Output(ev.Line.Msg, terminal.WithStyle(ev.Line.Style))
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_NamedValues_:
					var values []terminal.NamedValue

					for _, tnv := range ev.NamedValues.Values {
						values = append(values, terminal.NamedValue{
							Name:  tnv.Name,
							Value: tnv.Value,
						})
					}

					ui.NamedValues(values)
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_Status_:
					if tstatus == nil {
						tstatus = ui.Status()
						defer tstatus.Close()
					}

					if ev.Status.Msg == "" && !ev.Status.Step {
						tstatus.Close()
					} else if ev.Status.Step {
						tstatus.Step(ev.Status.Status, ev.Status.Msg)
					} else {
						tstatus.Update(ev.Status.Msg)
					}
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_Raw_:
					if stdout == nil {
						stdout, stderr, err = ui.OutputWriters()
						if err != nil {
							return nil, err
						}
					}

					if ev.Raw.Stderr {
						stderr.Write(ev.Raw.Data)
					} else {
						stdout.Write(ev.Raw.Data)
					}
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_Table_:
					tbl := terminal.NewTable(ev.Table.Headers...)

					for _, row := range ev.Table.Rows {
						var trow []terminal.TableEntry

						for _, ent := range row.Entries {
							trow = append(trow, terminal.TableEntry{
								Value: ent.Value,
								Color: ent.Color,
							})
						}
					}

					ui.Table(tbl)
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_StepGroup_:
					if sg != nil {
						sg.Wait()
					}

					if !ev.StepGroup.Close {
						sg = ui.StepGroup()
					}
				case *vagrant_server.GetJobStreamResponse_Terminal_Event_Step_:
					if sg == nil {
						continue
					}

					step, ok := steps[ev.Step.Id]
					if !ok {
						step = &stepData{
							Step: sg.Add(ev.Step.Msg),
						}
						steps[ev.Step.Id] = step
					} else {
						if ev.Step.Msg != "" {
							step.Update(ev.Step.Msg)
						}
					}

					if ev.Step.Status != "" {
						if ev.Step.Status == terminal.StatusAbort {
							step.Abort()
						} else {
							step.Status(ev.Step.Status)
						}
					}

					if len(ev.Step.Output) > 0 {
						if step.out == nil {
							step.out = step.TermOutput()
						}

						step.out.Write(ev.Step.Output)
					}

					if ev.Step.Close {
						step.Done()
					}
				default:
					c.logger.Error("Unknown terminal event seen", "type", hclog.Fmt("%T", ev))
				}
			}
		case *vagrant_server.GetJobStreamResponse_State_:
			// Stop any state event timers if we have any since the state
			// has changed and we don't want to output that information anymore.
			if stateEventTimer != nil {
				stateEventTimer.Stop()
				stateEventTimer = nil
			}

			// For certain states, we do a quality of life UI message if
			// the wait time ends up being long.
			switch event.State.Current {
			case vagrant_server.Job_QUEUED:
				stateEventTimer = time.AfterFunc(stateEventPause, func() {
					ui.Output("Operation is queued. Waiting for runner assignment...",
						terminal.WithHeaderStyle())
					ui.Output("If you interrupt this command, the job will still run in the background.",
						terminal.WithInfoStyle())
				})

			case vagrant_server.Job_WAITING:
				stateEventTimer = time.AfterFunc(stateEventPause, func() {
					ui.Output("Operation is assigned to a runner. Waiting for start...",
						terminal.WithHeaderStyle())
					ui.Output("If you interrupt this command, the job will still run in the background.",
						terminal.WithInfoStyle())
				})
			}

		default:
			log.Warn("unknown stream event", "event", resp.Event)
		}
	}
}

const stateEventPause = 1500 * time.Millisecond
