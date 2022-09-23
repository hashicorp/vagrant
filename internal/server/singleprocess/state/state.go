// Package state manages the state that the singleprocess server has, providing
// operations to mutate that state safely as needed.
package state

import (
	"crypto/rand"
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-memdb"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

var (
	// schemas is used to register schemas within the state store. Other
	// files should use the init() callback to append to this.
	schemas []schemaFn

	// All the data persisted models defined. Other files should
	// use the init() callback to append to this list.
	models = []interface{}{}

	// dbIndexers is the list of functions to call to initialize the
	// in-memory indexes from the persisted db.
	dbIndexers []indexFn

	entropy = rand.Reader

	// Error returned when proto value passed is nil
	ErrEmptyProtoArgument = errors.New("no proto value provided")

	// Error returned when a proto reference does not include its parent
	ErrMissingProtoParent = errors.New("proto reference does not include parent")
)

// indexFn is the function type for initializing in-memory indexes from
// persisted data. This is usually specified as a method handle to a
// *State method.
//
// The bolt.Tx is read-only while the memdb.Txn is a write transaction.
type indexFn func(*State, *memdb.Txn) error

type Model struct {
	ID        uint `gorm:"primaryKey"`
	CreatedAt time.Time
	UpdatedAt time.Time
}

// State is the primary API for state mutation for the server.
type State struct {
	// Connection to our database
	db *gorm.DB

	// inmem is our in-memory database that stores ephemeral data in an
	// easier-to-query way. Some of this data may be periodically persisted
	// but most of this data is meant to be lost when the process restarts.
	inmem *memdb.MemDB

	// indexers is used to track whether an indexer was called. This is
	// initialized during New and set to nil at the end of New.
	indexers map[uintptr]struct{}

	// indexedJobs indicates how many job records we are tracking in memory
	indexedJobs int

	// Used to track prune records
	pruneMu sync.Mutex

	// Where to log to
	log hclog.Logger
}

// New initializes a new State store.
func New(log hclog.Logger, db *gorm.DB) (*State, error) {
	log = log.Named("state")
	err := db.AutoMigrate(models...)
	if err != nil {
		log.Trace("failure encountered during auto migration",
			"error", err,
		)
		return nil, err
	}

	// Create the in-memory DB
	inmem, err := memdb.NewMemDB(stateStoreSchema())
	if err != nil {
		log.Trace("failed to setup in-memory database", "error", err)
		return nil, err
	}

	s := &State{
		db:    db,
		inmem: inmem,
		log:   log,
	}

	// Initialize the in-memory indicies
	memTxn := inmem.Txn(true)
	defer memTxn.Abort()
	for _, indexer := range dbIndexers {
		if err := indexer(s, memTxn); err != nil {
			return nil, err
		}

	}
	memTxn.Commit()

	return s, nil
}

// Close should be called to gracefully close any resources.
func (s *State) Close() error {
	db, err := s.db.DB()
	if err != nil {
		return err
	}
	return db.Close()
}

// Prune should be called in a on a regular interval to allow State
// to prune out old data.
func (s *State) Prune() error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	// Prune jobs from memdb
	jobs, err := s.jobsPruneOld(memTxn, maximumJobsInMem)
	if err != nil {
		return err
	}
	s.log.Debug("Finished pruning data",
		"removed-jobs", jobs,
	)
	memTxn.Commit()

	return nil
}

// schemaFn is an interface function used to create and return new memdb schema
// structs for constructing an in-memory db.
type schemaFn func() *memdb.TableSchema

// stateStoreSchema is used to return the combined schema for the state store.
func stateStoreSchema() *memdb.DBSchema {
	// Create the root DB schema
	db := &memdb.DBSchema{
		Tables: make(map[string]*memdb.TableSchema),
	}

	// Add the tables to the root schema
	for _, fn := range schemas {
		schema := fn()
		if _, ok := db.Tables[schema.Name]; ok {
			panic(fmt.Sprintf("duplicate table name: %s", schema.Name))
		}

		db.Tables[schema.Name] = schema
	}

	return db
}

// Provides db for searching
// NOTE: In most cases this should be used instead of accessing `db`
// directly when searching for values to ensure all associations are
// fully loaded in the results.
func (s *State) search() *gorm.DB {
	return s.db.Preload(clause.Associations)
}

// Convert error to a GRPC status error when dealing with lookups
func lookupErrorToStatus(
	typeName string, // thing trying to be found (basis, project, etc)
	err error, // error to convert
) error {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return errorToStatus(fmt.Errorf("failed to locate %s (%w)", typeName, err))
	}

	if errors.Is(err, ErrEmptyProtoArgument) || errors.Is(err, ErrMissingProtoParent) {
		return errorToStatus(fmt.Errorf("cannot lookup %s (%w)", typeName, err))
	}

	return errorToStatus(fmt.Errorf("unexpected error encountered during %s lookup (%w)", typeName, err))
}

// Convert error to GRPC status error when failing to save
func saveErrorToStatus(
	typeName string, // thing trying to be saved
	err error, // error to convert
) error {
	var vErr validation.Error
	if errors.Is(err, ErrEmptyProtoArgument) ||
		errors.Is(err, ErrMissingProtoParent) ||
		errors.As(err, &vErr) {
		return errorToStatus(fmt.Errorf("cannot save %s (%w)", typeName, err))
	}

	return errorToStatus(fmt.Errorf("unexpected error encountered while saving %s (%w)", typeName, err))
}

// Convert error to GRPC status error when failing to delete
func deleteErrorToStatus(
	typeName string, // thing trying to be deleted
	err error, // error to convert
) error {
	return errorToStatus(fmt.Errorf("unexpected error encountered while deleting %s (%w)", typeName, err))
}

// Convert error to a GRPC status error
func errorToStatus(
	err error, // error to convert
) error {
	if errors.Is(err, gorm.ErrRecordNotFound) {
		return status.Error(codes.NotFound, err.Error())
	}
	var vErr validation.Error
	if errors.Is(err, ErrEmptyProtoArgument) ||
		errors.Is(err, ErrMissingProtoParent) ||
		errors.As(err, &vErr) {
		return status.Error(codes.FailedPrecondition, err.Error())
	}

	return status.Error(codes.Internal, err.Error())
}
