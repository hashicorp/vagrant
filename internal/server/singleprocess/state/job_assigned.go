package state

import (
	"reflect"

	"github.com/hashicorp/go-memdb"
	//	pb "github.com/hashicorp/vagrant/internal/server/gen"
)

// This file has the methods related to tracking assigned jobs. I pulled this
// out into a separate file since the job queueing logic is already quite long.

// blockOps are the operation types that can NOT be run in parallel. Anything
// in this list will block if any other operation in this list is running
// for the app and workspace.
// TODO(spox): can we make this dynamic based on metadata provided via action request?
var blockOps = map[reflect.Type]struct{}{
	// reflect.TypeOf((*pb.Job_Destroy)(nil)): {},
}

func init() {
	schemas = append(schemas, jobAssignedSchema)
}

const (
	jobAssignedTableName   = "jobs-assigned"
	jobAssignedIdIndexName = "id"
)

func jobAssignedSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: jobAssignedTableName,
		Indexes: map[string]*memdb.IndexSchema{
			jobAssignedIdIndexName: {
				Name:         jobAssignedIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Basis",
							Lowercase: true,
						},

						&memdb.StringFieldIndex{
							Field:     "Project",
							Lowercase: true,
						},

						&memdb.StringFieldIndex{
							Field:     "Machine",
							Lowercase: true,
						},
					},
				},
			},
		},
	}
}

type jobAssignedIndex struct {
	ResourceId string
}

// jobIsBlocked will return true if the given job is currently blocked because
// a job with the same basis/project/machine is executing.
//
// If ws is set then a watch will be added for any changes in assigned jobs.
// Note that this trigger doesn't mean that the blocking is necessarily gone
// but something changed to warrant rechecking.
func (s *State) jobIsBlocked(memTxn *memdb.Txn, idx *jobIndex, ws memdb.WatchSet) (bool, error) {
	// If this job represents a parallelizable operation type, then allow it.
	if _, ok := blockOps[idx.OpType]; !ok {
		return false, nil
	}

	// Look for this project/app/ws combo
	watchCh, value, err := memTxn.FirstWatch(
		jobAssignedTableName,
		jobAssignedIdIndexName,
		idx.Scope.GetResourceId(),
	)
	if err != nil {
		return false, err
	}
	if ws != nil {
		ws.Add(watchCh)
	}

	// Blocked if we have a record
	return value != nil, nil
}

// jobAssignedSet records the given job as assigned.
func (s *State) jobAssignedSet(memTxn *memdb.Txn, idx *jobIndex, assigned bool) error {
	// If this job represents a parallelizable operation type, then do nothing.
	if _, ok := blockOps[idx.OpType]; !ok {
		return nil
	}

	rec := &jobAssignedIndex{
		ResourceId: idx.Scope.GetResourceId(),
	}

	if assigned {
		return memTxn.Insert(jobAssignedTableName, rec)
	}

	return memTxn.Delete(jobAssignedTableName, rec)
}
