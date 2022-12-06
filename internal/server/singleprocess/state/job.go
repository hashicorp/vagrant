package state

import (
	"context"
	"fmt"
	"reflect"
	"sort"
	"time"

	"github.com/hashicorp/go-memdb"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/logbuffer"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var (
	jobBucket = []byte("jobs")

	jobWaitingTimeout   = 2 * time.Minute
	jobHeartbeatTimeout = 2 * time.Minute
)

const (
	jobTableName          = "jobs"
	jobIdIndexName        = "id"
	jobStateIndexName     = "state"
	jobQueueTimeIndexName = "queue-time"
	jobTargetIdIndexName  = "target-id"
	maximumJobsInMem      = 10000
)

func init() {
	dbBuckets = append(dbBuckets, jobBucket)
	dbIndexers = append(dbIndexers, (*State).jobIndexInit)
	schemas = append(schemas, jobSchema)
}

func jobSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: jobTableName,
		Indexes: map[string]*memdb.IndexSchema{
			jobIdIndexName: {
				Name:         jobIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field: "Id",
				},
			},

			jobStateIndexName: {
				Name:         jobStateIndexName,
				AllowMissing: true,
				Unique:       false,
				Indexer: &memdb.IntFieldIndex{
					Field: "State",
				},
			},

			jobQueueTimeIndexName: {
				Name:         jobQueueTimeIndexName,
				AllowMissing: true,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.IntFieldIndex{
							Field: "State",
						},

						&IndexTime{
							Field: "QueueTime",
							Asc:   true,
						},
					},
				},
			},

			jobTargetIdIndexName: {
				Name:         jobTargetIdIndexName,
				AllowMissing: true,
				Unique:       true,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.IntFieldIndex{
							Field: "State",
						},

						&memdb.StringFieldIndex{
							Field:     "TargetRunnerId",
							Lowercase: true,
						},

						&IndexTime{
							Field: "QueueTime",
							Asc:   true,
						},
					},
				},
			},
		},
	}
}

type jobIndex struct {
	Id string

	// OpType is the operation type for the job.
	OpType reflect.Type

	// The basis/project/machine that this job is part of. This is used
	// to determine if the job is blocked. See job_assigned.go for more details.
	Basis   *vagrant_plugin_sdk.Ref_Basis
	Project *vagrant_plugin_sdk.Ref_Project
	Target  *vagrant_plugin_sdk.Ref_Target

	// QueueTime is the time that the job was queued.
	QueueTime time.Time

	// TargetAny will be true if this job targets anything
	TargetAny bool

	// TargetRunnerId is the ID of the runner to target.
	TargetRunnerId string

	// State is the current state of this job.
	State vagrant_server.Job_State

	// StateTimer holds a timer that is usually acting as a timeout mechanism
	// on the current state. When the state changes, the timer should be cancelled.
	StateTimer *time.Timer

	// OutputBuffer stores the terminal output
	OutputBuffer *logbuffer.Buffer
}

// A helper, pulled out rather than on a value to allow it to be used against
// vagrant_server.Job,s and jobIndex's alike.
func jobIsCompleted(state vagrant_server.Job_State) bool {
	switch state {
	case vagrant_server.Job_ERROR, vagrant_server.Job_SUCCESS:
		return true
	default:
		return false
	}
}

// Job is the exported structure that is returned for most state APIs
// and gives callers access to more information than the pure job structure.
type Job struct {
	// Full job structure.
	*vagrant_server.Job

	// OutputBuffer is the terminal output for this job. This is a buffer
	// that may not contain the full amount of output depending on the
	// time of connection.
	OutputBuffer *logbuffer.Buffer

	// Blocked is true if this job is blocked on another job for the same
	// project/app/workspace.
	Blocked bool
}

// JobCreate queues the given job.
func (s *State) JobCreate(jobpb *vagrant_server.Job) error {
	txn := s.inmem.Txn(true)
	defer txn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.jobCreate(dbTxn, txn, jobpb)
	})
	if err == nil {
		txn.Commit()
	}

	return err
}

// JobList returns the list of jobs.
func (s *State) JobList() ([]*vagrant_server.Job, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	iter, err := memTxn.Get(jobTableName, jobIdIndexName+"_prefix", "")
	if err != nil {
		return nil, err
	}

	var result []*vagrant_server.Job
	for {
		next := iter.Next()
		if next == nil {
			break
		}
		idx := next.(*jobIndex)

		var job *vagrant_server.Job
		err = s.db.View(func(dbTxn *bolt.Tx) error {
			job, err = s.jobById(dbTxn, idx.Id)
			return err
		})

		result = append(result, job)
	}

	return result, nil
}

// JobById looks up a job by ID. The returned Job will be a deep copy
// of the job so it is safe to read/write. If the job can't be found,
// a nil result with no error is returned.
func (s *State) JobById(id string, ws memdb.WatchSet) (*Job, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	watchCh, raw, err := memTxn.FirstWatch(jobTableName, jobIdIndexName, id)
	if err != nil {
		return nil, err
	}

	ws.Add(watchCh)

	if raw == nil {
		return nil, nil
	}
	jobIdx := raw.(*jobIndex)

	// Get blocked status if it is queued.
	var blocked bool
	if jobIdx.State == vagrant_server.Job_QUEUED {
		blocked, err = s.jobIsBlocked(memTxn, jobIdx, ws)
		if err != nil {
			return nil, err
		}
	}

	var job *vagrant_server.Job
	err = s.db.View(func(dbTxn *bolt.Tx) error {
		job, err = s.jobById(dbTxn, jobIdx.Id)
		return err
	})

	result := jobIdx.Job(job)
	result.Blocked = blocked

	return result, err
}

// JobAssignForRunner will wait for and assign a job to a specific runner.
// This will automatically evaluate any conditions that the runner and/or
// job may have on assignability.
//
// The assigned job is put into a "waiting" state until the runner
// acks the assignment which can be set with JobAck.
//
// If ctx is provided and assignment has to block waiting for new jobs,
// this will cancel when the context is done.
func (s *State) JobAssignForRunner(ctx context.Context, r *vagrant_server.Runner) (*Job, error) {
RETRY_ASSIGN:
	txn := s.inmem.Txn(false)
	defer txn.Abort()

	// Turn our runner into a runner record so we can more efficiently assign
	runnerRec := newRunnerRecord(r)

	// candidateQuery finds candidate jobs to assign.
	type candidateFunc func(*memdb.Txn, memdb.WatchSet, *runnerRecord) (*jobIndex, error)
	candidateQuery := []candidateFunc{
		s.jobCandidateById,
		s.jobCandidateAny,
	}

	// If the runner is by id only, then explicitly set it to by id only.
	// We explicitly set the full list so that if we add more candidate
	// searches in the future, we're unlikely to break this.
	if r.ByIdOnly {
		candidateQuery = []candidateFunc{s.jobCandidateById}
	}

	// Build the list of candidates
	var candidates []*jobIndex
	ws := memdb.NewWatchSet()
	for _, f := range candidateQuery {
		job, err := f(txn, ws, runnerRec)
		if err != nil {
			return nil, err
		}
		if job == nil {
			continue
		}

		candidates = append(candidates, job)
	}

	// If we have no candidates, then we have to wait for a job to show up.
	// We set up a blocking query on the job table for a non-assigned job.
	if len(candidates) == 0 {
		iter, err := txn.Get(jobTableName, jobStateIndexName, vagrant_server.Job_QUEUED)
		if err != nil {
			return nil, err
		}

		ws.Add(iter.WatchCh())
	}

	// We're done reading so abort the transaction
	txn.Abort()

	// If we have a watch channel set that means we didn't find any
	// results and we need to retry after waiting for changes.
	if len(candidates) == 0 {
		ws.WatchCtx(ctx)
		if err := ctx.Err(); err != nil {
			return nil, err
		}

		goto RETRY_ASSIGN
	}

	// We sort our candidates by queue time so that we can find the earliest
	sort.Slice(candidates, func(i, j int) bool {
		return candidates[i].QueueTime.Before(candidates[j].QueueTime)
	})

	// Grab a write lock since we're going to delete, modify, add the
	// job that we chose. No need to defer here since the first defer works
	// at the top of the func.
	//
	// Write locks are exclusive so this will ensure we're the only one
	// writing at a time. This lets us be sure we're the only one "assigning"
	// a job candidate.
	txn = s.inmem.Txn(true)
	for _, job := range candidates {
		// Get the job
		raw, err := txn.First(jobTableName, jobIdIndexName, job.Id)
		if err != nil {
			return nil, err
		}
		if raw == nil {
			// The job no longer exists. It may be canceled or something.
			// Invalid candidate, continue to next.
			continue
		}

		// We need to verify that in the time between our candidate search
		// and our write lock acquisition, that this job hasn't been assigned,
		// canceled, etc. If so, this is an invalid candidate.
		job := raw.(*jobIndex)
		if job == nil || job.State != vagrant_server.Job_QUEUED {
			continue
		}

		// We also need to recheck that we aren't blocked. If we're blocked
		// now then we need to skip this job.
		if blocked, err := s.jobIsBlocked(txn, job, nil); blocked {
			continue
		} else if err != nil {
			return nil, err
		}

		// Update our state and update our on-disk job
		job.State = vagrant_server.Job_WAITING
		result, err := s.jobReadAndUpdate(job.Id, func(jobpb *vagrant_server.Job) error {
			jobpb.State = job.State
			jobpb.AssignTime = timestamppb.New(time.Now())
			return nil
		})
		if err != nil {
			return nil, err
		}

		// Create our timer to requeue this if it isn't acked
		job.StateTimer = time.AfterFunc(jobWaitingTimeout, func() {
			s.log.Info("job ack timer expired", "job", job.Id, "timeout", jobWaitingTimeout)
			s.JobAck(job.Id, false)
		})

		if err := txn.Insert(jobTableName, job); err != nil {
			return nil, err
		}

		// Update our assignment state
		if err := s.jobAssignedSet(txn, job, true); err != nil {
			s.JobAck(job.Id, false)
			return nil, err
		}

		txn.Commit()
		return job.Job(result), nil
	}
	txn.Abort()

	// If we reached here, all of our candidates were invalid, we retry
	goto RETRY_ASSIGN
}

// JobAck acknowledges that a job has been accepted or rejected by the runner.
// If ack is false, then this will move the job back to the queued state
// and be eligible for assignment.
func (s *State) JobAck(id string, ack bool) (*Job, error) {
	txn := s.inmem.Txn(true)
	defer txn.Abort()

	// Get the job
	raw, err := txn.First(jobTableName, jobIdIndexName, id)
	if err != nil {
		return nil, err
	}
	if raw == nil {
		return nil, status.Errorf(codes.NotFound, "job not found: %s", id)
	}
	job := raw.(*jobIndex)

	// If the job is not in the assigned state, then this is an error.
	if job.State != vagrant_server.Job_WAITING {
		return nil, status.Errorf(codes.FailedPrecondition,
			"job can't be acked from state: %s",
			job.State.String())
	}

	result, err := s.jobReadAndUpdate(job.Id, func(jobpb *vagrant_server.Job) error {
		if ack {
			// Set to accepted
			job.State = vagrant_server.Job_RUNNING
			jobpb.State = job.State
			jobpb.AckTime = timestamppb.New(time.Now())

			// We also initialize the output buffer here because we can
			// expect output to begin streaming in.
			job.OutputBuffer = logbuffer.New()
		} else {
			// Set to queued
			job.State = vagrant_server.Job_QUEUED
			jobpb.State = job.State
			jobpb.AssignTime = nil
		}

		return nil
	})
	if err != nil {
		return nil, err
	}

	// Cancel our timer
	if job.StateTimer != nil {
		job.StateTimer.Stop()
		job.StateTimer = nil
	}

	// Create a new timer that we'll use for our heartbeat. After this
	// timer expires, the job will immediately move to an error state.
	job.StateTimer = time.AfterFunc(jobHeartbeatTimeout, func() {
		s.log.Info("canceling job due to heartbeat timeout", "job", job.Id)
		// Force cancel
		err := s.JobCancel(job.Id, true)
		if err != nil {
			s.log.Error("error canceling job due to heartbeat failure", "error", err, "job", job.Id)
		}
	})

	s.log.Debug("heartbeat timer set", "job", job.Id, "timeout", jobHeartbeatTimeout)

	// Insert to update
	if err := txn.Insert(jobTableName, job); err != nil {
		return nil, err
	}

	// Update our assigned state if we nacked
	if !ack {
		if err := s.jobAssignedSet(txn, job, false); err != nil {
			return nil, err
		}
	}

	txn.Commit()
	return job.Job(result), nil
}

// JobComplete marks a running job as complete. If an error is given,
// the job is marked as failed (a completed state). If no error is given,
// the job is marked as successful.
func (s *State) JobComplete(id string, result *vagrant_server.Job_Result, cerr error) error {
	txn := s.inmem.Txn(true)
	defer txn.Abort()

	// Get the job
	raw, err := txn.First(jobTableName, jobIdIndexName, id)
	if err != nil {
		return err
	}
	if raw == nil {
		return status.Errorf(codes.NotFound, "job not found: %s", id)
	}
	job := raw.(*jobIndex)

	// Update our assigned state
	if err := s.jobAssignedSet(txn, job, false); err != nil {
		return err
	}

	// If the job is not in the assigned state, then this is an error.
	if job.State != vagrant_server.Job_RUNNING {
		return status.Errorf(codes.FailedPrecondition,
			"job can't be completed from state: %s",
			job.State.String())
	}

	_, err = s.jobReadAndUpdate(job.Id, func(jobpb *vagrant_server.Job) error {
		// Set to complete, assume success for now
		job.State = vagrant_server.Job_SUCCESS
		jobpb.State = job.State
		jobpb.Result = result
		jobpb.CompleteTime = timestamppb.New(time.Now())

		if cerr != nil {
			job.State = vagrant_server.Job_ERROR
			jobpb.State = job.State

			st, _ := status.FromError(cerr)
			jobpb.Error = st.Proto()
		}

		return nil
	})
	if err != nil {
		return err
	}

	// End the job
	job.End()

	// Insert to update
	if err := txn.Insert(jobTableName, job); err != nil {
		return err
	}

	txn.Commit()
	return nil
}

// JobCancel marks a job as cancelled. This will set the internal state
// and request the cancel but if the job is running then it is up to downstream
// to listen for and react to Job changes for cancellation.
func (s *State) JobCancel(id string, force bool) error {
	txn := s.inmem.Txn(true)
	defer txn.Abort()

	// Get the job
	raw, err := txn.First(jobTableName, jobIdIndexName, id)
	if err != nil {
		return err
	}
	if raw == nil {
		return status.Errorf(codes.NotFound, "job not found: %s", id)
	}
	job := raw.(*jobIndex)

	if err := s.jobCancel(txn, job, force); err != nil {
		return err
	}

	txn.Commit()
	return nil
}

func (s *State) jobCancel(txn *memdb.Txn, job *jobIndex, force bool) error {
	oldState := job.State

	// How we handle cancel depends on the state
	switch job.State {
	case vagrant_server.Job_ERROR, vagrant_server.Job_SUCCESS:
		s.log.Debug("attempted to cancel completed job", "state", job.State.String(), "job", job.Id)
		// Jobs that are already completed do nothing for cancellation.
		// We do not mark that they were requested as cancelled since they
		// completed fine.
		return nil

	case vagrant_server.Job_QUEUED:
		// For queued jobs, we immediately transition them to an error state.
		job.State = vagrant_server.Job_ERROR

	case vagrant_server.Job_WAITING, vagrant_server.Job_RUNNING:
		// For these states, we just need to mark it as cancelled and have
		// downstream listeners complete the job. However, if we are forcing
		// then we immediately transition to error.
		if force {
			job.State = vagrant_server.Job_ERROR
			job.End()
		}
	}

	s.log.Debug("changing job state for cancel", "old-state", oldState.String(), "new-state", job.State.String(), "job", job.Id, "force", force)

	if force && job.State == vagrant_server.Job_ERROR {
		// Update our assigned state to unblock future jobs
		if err := s.jobAssignedSet(txn, job, false); err != nil {
			return err
		}
	}

	// Persist the on-disk data
	_, err := s.jobReadAndUpdate(job.Id, func(jobpb *vagrant_server.Job) error {
		jobpb.State = job.State
		jobpb.CancelTime = timestamppb.New(time.Now())

		// If we transitioned to the error state we note that we were force
		// cancelled. We can only be in the error state under that scenario
		// since otherwise we would've returned early.
		if jobpb.State == vagrant_server.Job_ERROR {
			jobpb.Error = status.New(codes.Canceled, "canceled").Proto()
		}

		return nil
	})
	if err != nil {
		return err
	}

	// Store the inmem data
	// This will be seen by a currently running RunnerJobStream goroutine, which
	// will then see that the job has been canceled and send the request to cancel
	// down to the runner.
	if err := txn.Insert(jobTableName, job); err != nil {
		return err
	}

	return nil
}

// JobHeartbeat resets the heartbeat timer for a running job. If the job
// is not currently running this does nothing, it will not return an error.
// If the job doesn't exist then this will return an error.
func (s *State) JobHeartbeat(id string) error {
	txn := s.inmem.Txn(true)
	defer txn.Abort()

	if err := s.jobHeartbeat(txn, id); err != nil {
		return err
	}

	txn.Commit()
	return nil
}

func (s *State) jobHeartbeat(txn *memdb.Txn, id string) error {
	// Get the job
	raw, err := txn.First(jobTableName, jobIdIndexName, id)
	if err != nil {
		return err
	}
	if raw == nil {
		return status.Errorf(codes.NotFound, "job not found: %s", id)
	}
	job := raw.(*jobIndex)

	// If the job is not in the running state, we do nothing.
	if job.State != vagrant_server.Job_RUNNING {
		return nil
	}

	// If the state timer is nil... that is weird but we ignore it here.
	// It is up to other parts of the job system to ensure a running
	// job has a heartbeat timer.
	if job.StateTimer == nil {
		s.log.Info("job with no start timer detected", "job", id)
		return nil
	}

	// Reset the timer
	job.StateTimer.Reset(jobHeartbeatTimeout)

	return nil
}

// JobExpire expires a job. This will cancel the job if it is still queued.
func (s *State) JobExpire(id string) error {
	txn := s.inmem.Txn(true)
	defer txn.Abort()

	// Get the job
	raw, err := txn.First(jobTableName, jobIdIndexName, id)
	if err != nil {
		return err
	}
	if raw == nil {
		return status.Errorf(codes.NotFound, "job not found: %s", id)
	}
	job := raw.(*jobIndex)

	// How we handle depends on the state
	switch job.State {
	case vagrant_server.Job_QUEUED, vagrant_server.Job_WAITING:
		if err := s.jobCancel(txn, job, false); err != nil {
			return err
		}

	default:
	}

	txn.Commit()
	return nil
}

// JobIsAssignable returns whether there is a registered runner that
// meets the requirements to run this job.
//
// If this returns true, the job if queued should eventually be assigned
// successfully to a runner. An assignable result does NOT mean that it will be
// in queue a short amount of time.
//
// Note the result is a point-in-time result. If the only candidate runners
// deregister between this returning true and queueing, the job may still
// sit in a queue indefinitely.
func (s *State) JobIsAssignable(ctx context.Context, jobpb *vagrant_server.Job) (bool, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	// If we have no runners, we cannot be assigned
	empty, err := s.runnerEmpty(memTxn)
	if err != nil {
		return false, err
	}
	if empty {
		return false, nil
	}

	// If we have a special targeting constraint, that has to be met
	var iter memdb.ResultIterator
	var targetCheck func(*vagrant_server.Runner) (bool, error)
	switch v := jobpb.TargetRunner.Target.(type) {
	case *vagrant_server.Ref_Runner_Any:
		// We need a special target check that disallows by ID only
		targetCheck = func(r *vagrant_server.Runner) (bool, error) {
			return !r.ByIdOnly, nil
		}

		iter, err = memTxn.LowerBound(runnerTableName, runnerIdIndexName, "")

	case *vagrant_server.Ref_Runner_Id:
		iter, err = memTxn.Get(runnerTableName, runnerIdIndexName, v.Id.Id)

	default:
		return false, fmt.Errorf("unknown runner target value: %#v", jobpb.TargetRunner.Target)
	}
	if err != nil {
		return false, err
	}

	for {
		raw := iter.Next()
		if raw == nil {
			// We're out of candidates and we found none.
			return false, nil
		}
		runner := raw.(*runnerRecord)

		// Check our target-specific check
		if targetCheck != nil {
			check, err := targetCheck(runner.Runner)
			if err != nil {
				return false, err
			}
			if !check {
				continue
			}
		}

		// This works!
		return true, nil
	}
}

// jobIndexInit initializes the config index from persisted data.
func (s *State) jobIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(jobBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.Job
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}

		idx, err := s.jobIndexSet(memTxn, k, &value)
		if err != nil {
			return err
		}

		// If the job was running or waiting, set it as assigned.
		if value.State == vagrant_server.Job_RUNNING || value.State == vagrant_server.Job_WAITING {
			if err := s.jobAssignedSet(memTxn, idx, true); err != nil {
				return err
			}
		}

		return nil
	})
}

// jobIndexSet writes an index record for a single job.
func (s *State) jobIndexSet(txn *memdb.Txn, id []byte, jobpb *vagrant_server.Job) (*jobIndex, error) {
	rec := &jobIndex{
		Id:      jobpb.Id,
		State:   jobpb.State,
		Basis:   jobpb.Basis,
		Project: jobpb.Project,
		Target:  jobpb.Target,
		OpType:  reflect.TypeOf(jobpb.Operation),
	}

	// Target
	if jobpb.TargetRunner == nil {
		return nil, fmt.Errorf("job target runner must be set")
	}
	switch v := jobpb.TargetRunner.Target.(type) {
	case *vagrant_server.Ref_Runner_Any:
		rec.TargetAny = true

	case *vagrant_server.Ref_Runner_Id:
		rec.TargetRunnerId = v.Id.Id

	default:
		return nil, fmt.Errorf("unknown runner target value: %#v", jobpb.TargetRunner.Target)
	}

	// Timestamps
	timestamps := []struct {
		Field *time.Time
		Src   *timestamppb.Timestamp
	}{
		{&rec.QueueTime, jobpb.QueueTime},
	}
	for _, ts := range timestamps {
		err := ts.Src.CheckValid()
		if err != nil {
			return nil, err
		}

		*ts.Field = ts.Src.AsTime()
	}

	// If this job is assigned. Then we have to start a nacking timer.
	// We reset the nack timer so it gives runners time to reconnect.
	if rec.State == vagrant_server.Job_WAITING {
		// Create our timer to requeue this if it isn't acked
		rec.StateTimer = time.AfterFunc(jobWaitingTimeout, func() {
			s.JobAck(rec.Id, false)
		})
	}

	// If this job is running, we need to restart a heartbeat timeout.
	// This should only happen on reinit. This is tested.
	if rec.State == vagrant_server.Job_RUNNING {
		rec.StateTimer = time.AfterFunc(jobHeartbeatTimeout, func() {
			// Force cancel
			s.JobCancel(rec.Id, true)
		})
	}

	// If we have an expiry, we need to set a timer to expire this job.
	if jobpb.ExpireTime != nil {
		now := time.Now()

		err := jobpb.ExpireTime.CheckValid()
		if err != nil {
			return nil, err
		}

		dur := jobpb.ExpireTime.AsTime().Sub(now)
		if dur < 0 {
			dur = 1
		}

		time.AfterFunc(dur, func() { s.JobExpire(jobpb.Id) })
	}

	// Insert the index
	return rec, txn.Insert(jobTableName, rec)
}

func (s *State) jobCreate(dbTxn *bolt.Tx, memTxn *memdb.Txn, jobpb *vagrant_server.Job) error {
	// Setup our initial job state
	var err error
	jobpb.State = vagrant_server.Job_QUEUED
	jobpb.QueueTime = timestamppb.New(time.Now())

	id := []byte(jobpb.Id)

	// Insert into bolt
	if err := dbPut(dbTxn.Bucket(jobBucket), id, jobpb); err != nil {
		return err
	}

	// Insert into the DB
	_, err = s.jobIndexSet(memTxn, id, jobpb)

	s.pruneMu.Lock()
	defer s.pruneMu.Unlock()
	s.indexedJobs++

	return err
}

func (s *State) jobById(dbTxn *bolt.Tx, id string) (*vagrant_server.Job, error) {
	var result vagrant_server.Job
	b := dbTxn.Bucket(jobBucket)
	return &result, dbGet(b, []byte(id), &result)
}

func (s *State) jobReadAndUpdate(id string, f func(*vagrant_server.Job) error) (*vagrant_server.Job, error) {
	var result *vagrant_server.Job
	var err error
	return result, s.db.Update(func(dbTxn *bolt.Tx) error {
		result, err = s.jobById(dbTxn, id)
		if err != nil {
			return err
		}

		// Modify
		if err := f(result); err != nil {
			return err
		}

		// Commit
		return dbPut(dbTxn.Bucket(jobBucket), []byte(id), result)
	})
}

// jobCandidateById returns the most promising candidate job to assign
// that is targeting a specific runner by ID.
func (s *State) jobCandidateById(memTxn *memdb.Txn, ws memdb.WatchSet, r *runnerRecord) (*jobIndex, error) {
	iter, err := memTxn.LowerBound(
		jobTableName,
		jobTargetIdIndexName,
		vagrant_server.Job_QUEUED,
		r.Id,
		time.Unix(0, 0),
	)
	if err != nil {
		return nil, err
	}

	for {
		raw := iter.Next()
		if raw == nil {
			break
		}

		job := raw.(*jobIndex)
		if job.State != vagrant_server.Job_QUEUED || job.TargetRunnerId != r.Id {
			continue
		}

		// If this job is blocked, it is not a candidate.
		if blocked, err := s.jobIsBlocked(memTxn, job, ws); err != nil {
			return nil, err
		} else if blocked {
			continue
		}

		return job, nil
	}

	return nil, nil
}

// jobCandidateAny returns the first candidate job that targets any runner.
func (s *State) jobCandidateAny(memTxn *memdb.Txn, ws memdb.WatchSet, r *runnerRecord) (*jobIndex, error) {
	iter, err := memTxn.LowerBound(
		jobTableName,
		jobQueueTimeIndexName,
		vagrant_server.Job_QUEUED,
		time.Unix(0, 0),
	)
	if err != nil {
		return nil, err
	}

	for {
		raw := iter.Next()
		if raw == nil {
			break
		}

		job := raw.(*jobIndex)
		if job.State != vagrant_server.Job_QUEUED || !job.TargetAny {
			continue
		}

		// If this job is blocked, it is not a candidate.
		if blocked, err := s.jobIsBlocked(memTxn, job, ws); err != nil {
			return nil, err
		} else if blocked {
			continue
		}

		return job, nil
	}

	return nil, nil
}

func (s *State) jobsPruneOld(memTxn *memdb.Txn, max int) (int, error) {
	// Prune from memdb
	return pruneOld(memTxn, pruneOp{
		lock:      &s.pruneMu,
		table:     jobTableName,
		index:     jobQueueTimeIndexName,
		indexArgs: []interface{}{vagrant_server.Job_QUEUED, time.Unix(0, 0)},
		max:       max,
		cur:       &s.indexedJobs,
		check: func(raw interface{}) bool {
			job := raw.(*jobIndex)
			return !jobIsCompleted(job.State)
		},
	})
}

func (s *State) JobsDBPruneOld(max int) (int, error) {
	cnt := dbCount(s.db, jobTableName)
	toDelete := cnt - max
	var deleted int

	// Prune jobs from boltDB
	s.db.Update(func(tx *bolt.Tx) error {
		bucket := tx.Bucket([]byte(jobTableName))
		cur := bucket.Cursor()
		key, _ := cur.First()
		for {
			if key == nil {
				break
			}
			// otherwise, prune this job! Once we've pruned enough jobs to get back
			// to the maximum, we stop pruning.
			toDelete--

			err := bucket.Delete(key)
			if err != nil {
				return err
			}

			deleted++
			if toDelete <= 0 {
				break
			}
			key, _ = cur.Next()
		}
		return nil
	})
	return deleted, nil
}

// Job returns the Job for an index.
func (idx *jobIndex) Job(jobpb *vagrant_server.Job) *Job {
	return &Job{
		Job:          jobpb,
		OutputBuffer: idx.OutputBuffer,
	}
}

// End notes this job is complete and performs any cleanup on the index.
func (idx *jobIndex) End() {
	if idx.StateTimer != nil {
		idx.StateTimer.Stop()
		idx.StateTimer = nil
	}
}
