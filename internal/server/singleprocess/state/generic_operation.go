package state

import (
	"errors"
	"fmt"
	"reflect"
	"strings"
	"sync/atomic"
	"time"

	"github.com/hashicorp/go-memdb"
	"github.com/mitchellh/go-testing-interface"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/protobuf/proto"

	//	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// appOperation is an abstraction on any "operation" that may happen to
// an app such as a build, push, etc. This allows uniform API calls on
// top of operations at a basic level.
type genericOperation struct {
	// Struct is the record structure used for this operation. Struct is
	// expected to have the following fields with the following types. The
	// names and types must match exactly.
	//
	//   - required: Id string
	//   - required: Status *vagrant_server.Status
	//
	// It may also have the special field "Preload". If this field exists,
	// it is automatically set to nil on disk and set to empty on read. This
	// field is expected to be used for just-in-time data loading that is not
	// persisted.
	//
	Struct interface{}

	// Bucket is the global bucket for all records of this operation.
	Bucket []byte

	// seq is the previous sequence number to set. This is initialized by the
	// index init on server boot and `sync/atomic` should be used to increment
	// it on each use.
	//
	// NOTE: Currently in waypoint the sequence is defined via app + seq number.
	// Since our operations can be based on the basis, project, or machine we
	// can't follow the same format. Instead, we will track a sequence against
	// the basis and against the project. For the machine based operations, it
	// will still just use project.
	// NOTE(spox): These need to be pruned when a project is deleted
	seqBasis   map[string]*uint64
	seqProject map[string]*uint64
}

// Test validates that the operation struct is setup properly. This
// is expected to be called in a unit test.
func (op *genericOperation) Test(t testing.T) {
	t.Fatalf("not implemented")
}

// register should be called in init() to register this operation with
// all the proper global variables to setup the state for this operation.
func (op *genericOperation) register() {
	dbBuckets = append(dbBuckets, op.Bucket)
	dbIndexers = append(dbIndexers, op.indexInit)
	schemas = append(schemas, op.memSchema)
}

// Put inserts or updates an operation record.
func (op *genericOperation) Put(s *State, update bool, value proto.Message) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return op.dbPut(s, dbTxn, memTxn, update, value)
	})
	if err == nil {
		memTxn.Commit()
	}

	return err
}

// Get gets an operation record by reference.
func (op *genericOperation) Get(s *State, ref *vagrant_server.Ref_Operation) (interface{}, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	result := op.newStruct()
	err := s.db.View(func(tx *bolt.Tx) error {
		var id string
		switch t := ref.Target.(type) {
		case *vagrant_server.Ref_Operation_Id:
			id = t.Id

		case *vagrant_server.Ref_Operation_TargetSequence:
			var err error
			id, err = op.getIdForSeq(s, tx, memTxn, t.TargetSequence.Number)
			if err != nil {
				return err
			}
		case *vagrant_server.Ref_Operation_ProjectSequence:
			var err error
			id, err = op.getIdForSeq(s, tx, memTxn, t.ProjectSequence.Number)
			if err != nil {
				return err
			}
		case *vagrant_server.Ref_Operation_BasisSequence:
			var err error
			id, err = op.getIdForSeq(s, tx, memTxn, t.BasisSequence.Number)
			if err != nil {
				return err
			}

		default:
			return status.Errorf(codes.FailedPrecondition,
				"unknown operation reference type: %T", ref.Target)
		}

		return op.dbGet(tx, []byte(id), result)
	})
	if err != nil {
		return nil, err
	}

	return result, nil
}

func (op *genericOperation) getIdForSeq(
	s *State,
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref interface{},
) (string, error) {
	var args []interface{}
	var number uint64

	if r, ok := ref.(*vagrant_server.Ref_TargetOperationSeq); ok {
		args = []interface{}{
			r.Target.Project.Basis.ResourceId,
			r.Target.Project.ResourceId,
			r.Target.ResourceId,
			r.Number,
		}
		number = r.Number
	} else if r, ok := ref.(*vagrant_server.Ref_ProjectOperationSeq); ok {
		args = []interface{}{
			r.Project.Basis.ResourceId,
			r.Project.ResourceId,
			"",
			r.Number,
		}
		number = r.Number
	} else if r, ok := ref.(*vagrant_server.Ref_BasisOperationSeq); ok {
		args = []interface{}{
			r.Basis.ResourceId,
			"",
			"",
			r.Number,
		}
		number = r.Number
	} else {
		return "", status.Errorf(codes.Internal,
			"unknown reference type provided for sequence number %d", number)
	}

	raw, err := memTxn.First(
		op.memTableName(),
		opSeqIndexName,
		args...,
	)
	if err != nil {
		return "", err
	}
	if raw == nil {
		return "", status.Errorf(codes.NotFound,
			"not found for sequence number %d", number)
	}

	idx := raw.(*operationIndexRecord)
	return idx.Id, nil
}

// List lists all the records.
func (op *genericOperation) List(s *State, opts *listOperationsOptions) ([]interface{}, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	// Set the proper index for our ordering
	idx := opStartTimeIndexName
	if opts.Order != nil {
		switch opts.Order.Order {
		case vagrant_server.OperationOrder_COMPLETE_TIME:
			idx = opCompleteTimeIndexName
		}
	}

	var ref interface{}
	var args []interface{}

	if opts.Machine != nil {
		args = []interface{}{
			opts.Machine.Project.Basis.ResourceId,
			opts.Machine.Project.ResourceId,
			opts.Machine.ResourceId,
			indexTimeLatest{},
		}
		ref = opts.Machine
	} else if opts.Project != nil {
		args = []interface{}{
			opts.Project.Basis.ResourceId,
			opts.Project.ResourceId,
			"",
			indexTimeLatest{},
		}
		ref = opts.Project
	} else if opts.Basis != nil {
		args = []interface{}{
			opts.Basis.ResourceId,
			"",
			"",
			indexTimeLatest{},
		}
		ref = opts.Basis
	} else {
		return nil, errors.New("must provide a Basis.Ref, Project.Ref, or Machine.Ref to List")
	}

	// Get the iterator for lower-bound based querying
	iter, err := memTxn.LowerBound(
		op.memTableName(),
		idx,
		args...,
	)

	if err != nil {
		return nil, err
	}

	var result []interface{}
	s.db.View(func(tx *bolt.Tx) error {
		for {
			current := iter.Next()
			if current == nil {
				return nil
			}

			record := current.(*operationIndexRecord)
			if !record.MatchRef(ref) {
				return nil
			}

			value := op.newStruct()
			if err := op.dbGet(tx, []byte(record.Id), value); err != nil {
				return err
			}

			if opts.PhysicalState > 0 {
				if raw := op.valueField(value, "State"); raw != nil {
					state := raw.(vagrant_server.Operation_PhysicalState)
					if state != opts.PhysicalState {
						continue
					}
				}
			}

			if len(opts.Status) > 0 {
				// Get our status field
				status := op.valueField(value, "Status").(*vagrant_server.Status)

				// Filter. If we don't match the filter, then ignore this result.
				if !statusFilterMatch(opts.Status, status) {
					continue
				}
			}

			result = append(result, value)

			// If we have a limit, check that now
			if o := opts.Order; o != nil && o.Limit > 0 && len(result) >= int(o.Limit) {
				return nil
			}
		}
	})

	return result, nil
}

// Latest gets the latest operation that was completed successfully.
func (op *genericOperation) Latest(
	s *State,
	ref interface{},
) (interface{}, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var args []interface{}

	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Target); ok {
		args = []interface{}{
			r.Project.Basis.ResourceId,
			r.Project.ResourceId,
			r.ResourceId,
			indexTimeLatest{},
		}
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Project); ok {
		args = []interface{}{
			r.Basis.ResourceId,
			r.ResourceId,
			"",
			indexTimeLatest{},
		}
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Basis); ok {
		args = []interface{}{
			r.ResourceId,
			"",
			"",
			indexTimeLatest{},
		}
	} else {
		return nil, status.Error(codes.Internal, "unknown reference type")
	}

	iter, err := memTxn.LowerBound(
		op.memTableName(),
		opCompleteTimeIndexName,
		args...,
	)
	if err != nil {
		return nil, err
	}

	for {
		raw := iter.Next()
		if raw == nil {
			break
		}

		record := raw.(*operationIndexRecord)
		if !record.MatchRef(ref) {
			break
		}

		v, err := op.Get(s, &vagrant_server.Ref_Operation{
			Target: &vagrant_server.Ref_Operation_Id{Id: record.Id},
		})
		if err != nil {
			return nil, err
		}

		// Shouldn't happen but if it does, return nothing.
		st := op.valueField(v, "Status")
		if st == nil {
			break
		}

		// State must be success.
		switch st.(*vagrant_server.Status).State {
		case vagrant_server.Status_SUCCESS:
			return v, nil
		}
	}

	return nil, status.Error(codes.NotFound, "none available")
}

// dbGet reads the value from the database.
func (op *genericOperation) dbGet(
	dbTxn *bolt.Tx,
	id []byte,
	result proto.Message,
) error {
	// Read the value
	if err := dbGet(dbTxn.Bucket(op.Bucket), []byte(id), result); err != nil {
		return err
	}

	// If there is a preload field, we want to set that to non-nil.
	if f := op.valueFieldReflect(result, "Preload"); f.IsValid() {
		f.Set(reflect.New(f.Type().Elem()))
	}

	return nil
}

// dbPut wites the value to the database and also sets up any index records.
// It expects to hold a write transaction to both bolt and memdb.
func (op *genericOperation) dbPut(
	s *State,
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	update bool,
	value proto.Message,
) (err error) {
	// Get our ref and ensure that it's created
	var ref interface{}
	for _, k := range []string{"Machine", "Project", "Basis"} {
		ref = op.valueField(value, k)
		if ref != nil {
			break
		}
	}

	if ref == nil {
		return status.Errorf(codes.Internal,
			"state: Machine, Project, or Basis must be set on value %T", value)
	}

	// Determine the type so we can default the put
	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Target); ok {
		_, err = s.targetGet(dbTxn, memTxn, r)
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Project); ok {
		_, err = s.projectGet(dbTxn, memTxn, r)
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Basis); ok {
		_, err = s.basisGet(dbTxn, memTxn, r)
	} else {
		err = status.Error(codes.Internal,
			fmt.Sprintf("state: Unable to default ref on value %T", value))
	}

	if err != nil {
		return
	}

	// Get the global bucket and write the value to it.
	b := dbTxn.Bucket(op.Bucket)

	id := []byte(op.valueField(value, "Id").(string))
	if update {
		// Load the value so that we can retain the values that are read-only.
		// At the same time we verify it exists
		existing := op.newStruct()
		err := op.dbGet(dbTxn, []byte(id), existing)
		if err != nil {
			if status.Code(err) == codes.NotFound {
				return status.Errorf(codes.NotFound, "record with ID %q not found for update", string(id))
			}

			return err
		}

		// Next, ensure that the fields we want to match are matched.
		matchFields := []string{"Sequence"}
		for _, name := range matchFields {
			f := op.valueFieldReflect(value, name)
			if !f.IsValid() {
				continue
			}

			fOld := op.valueFieldReflect(existing, name)
			if !fOld.IsValid() {
				continue
			}

			f.Set(fOld)
		}
	}

	// If we're not updating, then set the sequence number up if we have one.
	if !update {
		if f := op.valueFieldReflect(value, "Sequence"); f.IsValid() {
			seq := atomic.AddUint64(op.getSeq(ref), 1)
			f.Set(reflect.ValueOf(seq))
		}
	}

	// If there is a preload field, we want to set that to nil.
	if f := op.valueFieldReflect(value, "Preload"); f.IsValid() {
		f.Set(reflect.New(f.Type().Elem()))
	}

	if err := dbPut(b, id, value); err != nil {
		return err
	}

	// Create our index value and write that.
	return op.indexPut(s, memTxn, value)
}

// getSeq gets the pointer to the sequence number for the given reference.
// This can only safely be called while holding the memdb write transaction.
func (op *genericOperation) getSeq(ref interface{}) *uint64 {
	// Our ref can be a machine, project, or basis. Determine type and then
	// find sequence
	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Target); ok {
		// Machine operations are scoped to the project
		if op.seqProject == nil {
			op.seqProject = map[string]*uint64{}
		}
		k := strings.ToLower(r.ResourceId)
		seq, ok := op.seqProject[k]
		if !ok {
			var value uint64
			seq = &value
			op.seqProject[k] = seq
		}
		return seq
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Project); ok {
		if op.seqProject == nil {
			op.seqProject = map[string]*uint64{}
		}
		k := strings.ToLower(r.ResourceId)
		seq, ok := op.seqProject[k]
		if !ok {
			var value uint64
			seq = &value
			op.seqProject[k] = seq
		}
		return seq
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Basis); ok {
		if op.seqBasis == nil {
			op.seqBasis = map[string]*uint64{}
		}
		k := strings.ToLower(r.ResourceId)
		seq, ok := op.seqBasis[k]
		if !ok {
			var value uint64
			seq = &value
			op.seqBasis[k] = seq
		}
		return seq
	}

	return nil
}

// indexInit initializes the index table in memdb from all the records
// persisted on disk.
func (op *genericOperation) indexInit(s *State, dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(op.Bucket)
	return bucket.ForEach(func(k, v []byte) error {
		result := op.newStruct()
		if err := proto.Unmarshal(v, result); err != nil {
			return err
		}
		if err := op.indexPut(s, memTxn, result); err != nil {
			return err
		}

		// Check if this has a bigger sequence number
		if v := op.valueField(result, "Sequence"); v != nil {
			seq := v.(uint64)

			var current *uint64
			for _, k := range []string{"Machine", "Project", "Basis"} {
				ref := op.valueField(result, k)
				if ref == nil {
					continue
				}
				current = op.getSeq(ref)
				if current != nil {
					break
				}
			}
			if current != nil && seq > *current {
				*current = seq
			}
		}

		return nil
	})
}

// indexPut writes an index record for a single operation record.
func (op *genericOperation) indexPut(s *State, txn *memdb.Txn, value proto.Message) error {
	var startTime, completeTime time.Time

	statusRaw := op.valueField(value, "Status")
	if statusRaw != nil {
		statusVal := statusRaw.(*vagrant_server.Status)
		if statusVal != nil {
			if t := statusVal.StartTime; t != nil {
				err := t.CheckValid()
				if err != nil {
					return status.Errorf(codes.Internal, "time for operation can't be parsed")
				}

				startTime = t.AsTime()
			}

			if t := statusVal.CompleteTime; t != nil {
				err := t.CheckValid()
				if err != nil {
					return status.Errorf(codes.Internal, "time for operation can't be parsed")
				}

				completeTime = t.AsTime()
			}
		}
	}

	var sequence uint64
	if v := op.valueField(value, "Sequence"); v != nil {
		sequence = v.(uint64)
	}

	// Get any reference information we can extract from the operation
	var basis, project, machine string

	if ref := op.valueField(value, "Machine").(*vagrant_plugin_sdk.Ref_Target); ref != nil {
		basis = ref.Project.Basis.ResourceId
		project = ref.Project.ResourceId
		machine = ref.ResourceId
	} else if ref := op.valueField(value, "Project").(*vagrant_plugin_sdk.Ref_Project); ref != nil {
		basis = ref.Basis.ResourceId
		project = ref.ResourceId
	} else {
		ref := op.valueField(value, "Basis").(*vagrant_plugin_sdk.Ref_Basis)
		basis = ref.ResourceId
	}

	return txn.Insert(op.memTableName(), &operationIndexRecord{
		Id:           op.valueField(value, "Id").(string),
		Basis:        basis,
		Project:      project,
		Machine:      machine,
		Sequence:     sequence,
		StartTime:    startTime,
		CompleteTime: completeTime,
	})
}

func (op *genericOperation) valueField(value interface{}, field string) interface{} {
	fv := op.valueFieldReflect(value, field)
	if !fv.IsValid() {
		return nil
	}

	return fv.Interface()
}

func (op *genericOperation) valueFieldReflect(value interface{}, field string) reflect.Value {
	v := reflect.ValueOf(value)
	for v.Kind() == reflect.Ptr || v.Kind() == reflect.Interface {
		v = v.Elem()
	}

	return v.FieldByName(field)
}

// newStruct creates a pointer to a new value of the type of op.Struct.
// The value of op.Struct is usually itself a pointer so the result of this
// is a pointer to a pointer.
func (op *genericOperation) newStruct() proto.Message {
	return reflect.New(reflect.TypeOf(op.Struct).Elem()).Interface().(proto.Message)
}

func (op *genericOperation) memTableName() string {
	return strings.ToLower(string(op.Bucket))
}

// memSchema is the memdb schema for this operation.
func (op *genericOperation) memSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: op.memTableName(),
		Indexes: map[string]*memdb.IndexSchema{
			opIdIndexName: {
				Name:         opIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field: "Id",
				},
			},

			opStartTimeIndexName: {
				Name:         opStartTimeIndexName,
				AllowMissing: false,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Basis",
							Lowercase: false,
						},
						&memdb.StringFieldIndex{
							Field:     "Project",
							Lowercase: false,
						},

						&memdb.StringFieldIndex{
							Field:     "Machine",
							Lowercase: false,
						},

						&IndexTime{
							Field: "StartTime",
						},
					},
				},
			},

			opCompleteTimeIndexName: {
				Name:         opCompleteTimeIndexName,
				AllowMissing: false,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Basis",
							Lowercase: false,
						},
						&memdb.StringFieldIndex{
							Field:     "Project",
							Lowercase: false,
						},

						&memdb.StringFieldIndex{
							Field:     "Machine",
							Lowercase: false,
						},

						&IndexTime{
							Field: "CompleteTime",
						},
					},
				},
			},

			opSeqIndexName: {
				Name:         opSeqIndexName,
				AllowMissing: false,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Basis",
							Lowercase: false,
						},
						&memdb.StringFieldIndex{
							Field:     "Project",
							Lowercase: false,
						},

						&memdb.StringFieldIndex{
							Field:     "Machine",
							Lowercase: false,
						},

						&memdb.UintFieldIndex{
							Field: "Sequence",
						},
					},
				},
			},
		},
	}
}

// operationIndexRecord is the record we store in MemDB to perform
// indexed lookup operations by project, app, time, etc.
type operationIndexRecord struct {
	Id           string
	Basis        string
	Project      string
	Machine      string
	Sequence     uint64
	StartTime    time.Time
	CompleteTime time.Time
}

// MatchRef checks if a record matches the ref value. We have to provide
// this because we use LowerBound lookups in memdb and this may return
// a non-matching value at a certain point after iteration.
func (rec *operationIndexRecord) MatchRef(ref interface{}) bool {
	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Target); ok {
		return rec.Machine == r.ResourceId &&
			rec.Project == r.Project.ResourceId &&
			rec.Basis == r.Project.Basis.ResourceId
	}
	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Project); ok {
		return rec.Project == r.ResourceId &&
			rec.Basis == r.Basis.ResourceId
	}
	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Basis); ok {
		return rec.Basis == r.ResourceId
	}
	return false
}

const (
	opIdIndexName           = "id"            // id index name
	opStartTimeIndexName    = "start-time"    // start time index
	opCompleteTimeIndexName = "complete-time" // complete time index
	opSeqIndexName          = "seq"           // sequence number index
)

// listOperationsOptions are options that can be set for List calls on
// operations for filtering and limiting the response.
type listOperationsOptions struct {
	Basis         *vagrant_plugin_sdk.Ref_Basis
	Project       *vagrant_plugin_sdk.Ref_Project
	Machine       *vagrant_plugin_sdk.Ref_Target
	Status        []*vagrant_server.StatusFilter
	Order         *vagrant_server.OperationOrder
	PhysicalState vagrant_server.Operation_PhysicalState
}

func buildListOperationsOptions(ref interface{}, opts ...ListOperationOption) *listOperationsOptions {
	var result listOperationsOptions
	if r, ok := ref.(*vagrant_plugin_sdk.Ref_Basis); ok {
		result.Basis = r
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Project); ok {
		result.Project = r
	} else if r, ok := ref.(*vagrant_plugin_sdk.Ref_Target); ok {
		result.Machine = r
	} else {
		// TODO(spox): do something better here?
		panic("unknown reference type for list operations building")
	}

	for _, opt := range opts {
		opt(&result)
	}

	return &result
}

// ListOperationOption is an exported type to set configuration for listing operations.
type ListOperationOption func(opts *listOperationsOptions)

func ListWithBasis(b *vagrant_plugin_sdk.Ref_Basis) ListOperationOption {
	return func(opts *listOperationsOptions) {
		opts.Basis = b
	}
}

func ListWithProject(p *vagrant_plugin_sdk.Ref_Project) ListOperationOption {
	return func(opts *listOperationsOptions) {
		opts.Project = p
	}
}

func ListWithMachine(m *vagrant_plugin_sdk.Ref_Target) ListOperationOption {
	return func(opts *listOperationsOptions) {
		opts.Machine = m
	}
}

// ListWithStatusFilter sets a status filter.
func ListWithStatusFilter(f ...*vagrant_server.StatusFilter) ListOperationOption {
	return func(opts *listOperationsOptions) {
		opts.Status = f
	}
}

// ListWithOrder sets ordering on the list operation.
func ListWithOrder(f *vagrant_server.OperationOrder) ListOperationOption {
	return func(opts *listOperationsOptions) {
		opts.Order = f
	}
}

// ListWithPhysicalState sets ordering on the list operation.
func ListWithPhysicalState(f vagrant_server.Operation_PhysicalState) ListOperationOption {
	return func(opts *listOperationsOptions) {
		opts.PhysicalState = f
	}
}

// statusFilterMatch is a helper that compares a vagrant_server.Status to a set of
// StatusFilters. This returns true if the filters match.
func statusFilterMatch(
	filters []*vagrant_server.StatusFilter,
	status *vagrant_server.Status,
) bool {
	if len(filters) == 0 {
		return true
	}

NEXT_FILTER:
	for _, group := range filters {
		for _, filter := range group.Filters {
			if !statusFilterMatchSingle(filter, status) {
				continue NEXT_FILTER
			}
		}

		// If any match we match (OR)
		return true
	}

	return false
}

func statusFilterMatchSingle(
	filter *vagrant_server.StatusFilter_Filter,
	status *vagrant_server.Status,
) bool {
	switch f := filter.Filter.(type) {
	case *vagrant_server.StatusFilter_Filter_State:
		return status.State == f.State

	default:
		// unknown filters never match
		return false
	}
}
