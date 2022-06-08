package state

import (
	"fmt"
	"sort"

	"google.golang.org/protobuf/proto"
	"github.com/hashicorp/go-memdb"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	bolt "go.etcd.io/bbolt"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serversort "github.com/hashicorp/vagrant/internal/server/sort"
)

var configBucket = []byte("config")

func init() {
	dbBuckets = append(dbBuckets, configBucket)
	dbIndexers = append(dbIndexers, (*State).configIndexInit)
	schemas = append(schemas, configIndexSchema)
}

// ConfigSet writes a configuration variable to the data store.
func (s *State) ConfigSet(vs ...*vagrant_server.ConfigVar) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		for _, v := range vs {
			if err := s.configSet(dbTxn, memTxn, v); err != nil {
				return err
			}
		}

		return nil
	})
	if err == nil {
		memTxn.Commit()
	}

	return err
}

// ConfigGet gets all the configuration for the given request.
func (s *State) ConfigGet(req *vagrant_server.ConfigGetRequest) ([]*vagrant_server.ConfigVar, error) {
	return s.ConfigGetWatch(req, nil)
}

// ConfigGetWatch gets all the configuration for the given request. If a non-nil
// WatchSet is given, this can be watched for potential changes in the config.
func (s *State) ConfigGetWatch(req *vagrant_server.ConfigGetRequest, ws memdb.WatchSet) ([]*vagrant_server.ConfigVar, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result []*vagrant_server.ConfigVar
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.configGetMerged(dbTxn, memTxn, ws, req)
		return err
	})

	return result, err
}

func (s *State) configSet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	value *vagrant_server.ConfigVar,
) error {
	id := s.configVarId(value)

	// Get the global bucket and write the value to it.
	b := dbTxn.Bucket(configBucket)
	if value.Value == "" {
		if err := b.Delete(id); err != nil {
			return err
		}
	} else {
		if err := dbPut(b, id, value); err != nil {
			return err
		}
	}

	// Create our index value and write that.
	return s.configIndexSet(memTxn, id, value)
}

func (s *State) configGetMerged(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ws memdb.WatchSet,
	req *vagrant_server.ConfigGetRequest,
) ([]*vagrant_server.ConfigVar, error) {
	var mergeSet [][]*vagrant_server.ConfigVar
	switch scope := req.Scope.(type) {
	case *vagrant_server.ConfigGetRequest_Project:
		// For project scope, we just return the project scoped values.
		return s.configGetExact(dbTxn, memTxn, ws, scope.Project, req.Prefix)

		// TODO(spox): this should be a "something" (do we allow config for any machine,project,basis?)
		// case *vagrant_server.ConfigGetRequest_Application:

	case *vagrant_server.ConfigGetRequest_Runner:
		var err error
		mergeSet, err = s.configGetRunner(dbTxn, memTxn, ws, scope.Runner, req.Prefix)
		if err != nil {
			return nil, err
		}

	default:
		panic("unknown scope")
	}

	// Merge our merge set
	merged := make(map[string]*vagrant_server.ConfigVar)
	for _, set := range mergeSet {
		for _, v := range set {
			merged[v.Name] = v
		}
	}

	result := make([]*vagrant_server.ConfigVar, 0, len(merged))
	for _, v := range merged {
		result = append(result, v)
	}

	sort.Sort(serversort.ConfigName(result))

	return result, nil
}

// configGetExact returns the list of config variables for a scope
// exactly. By "exactly" we mean without any merging logic: if you request
// app-scoped variables, you'll get app-scoped variables. If a project-scoped
// variable matches, it will not be merged in.
func (s *State) configGetExact(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ws memdb.WatchSet,
	ref interface{}, // should be one of the *vagrant_server.Ref_ values.
	prefix string,
) ([]*vagrant_server.ConfigVar, error) {
	// We have to get the correct iterator based on the scope. We check the
	// scope and use the proper index to get the iterator here.
	var iter memdb.ResultIterator
	switch ref := ref.(type) {

	case *vagrant_plugin_sdk.Ref_Project:
		var err error
		iter, err = memTxn.Get(
			configIndexTableName,
			configIndexProjectIndexName+"_prefix",
			ref.ResourceId,
			prefix,
		)
		if err != nil {
			return nil, err
		}

	default:
		panic("unknown scope")
	}

	// Add to our watchset
	ws.Add(iter.WatchCh())

	// Go through the iterator and accumulate the results
	var result []*vagrant_server.ConfigVar
	b := dbTxn.Bucket(configBucket)
	for {
		current := iter.Next()
		if current == nil {
			break
		}

		var value vagrant_server.ConfigVar
		record := current.(*configIndexRecord)
		if err := dbGet(b, []byte(record.Id), &value); err != nil {
			return nil, err
		}

		result = append(result, &value)
	}

	return result, nil
}

// configGetRunner gets the config vars for a runner.
func (s *State) configGetRunner(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ws memdb.WatchSet,
	req *vagrant_server.Ref_RunnerId,
	prefix string,
) ([][]*vagrant_server.ConfigVar, error) {
	iter, err := memTxn.Get(
		configIndexTableName,
		configIndexRunnerIndexName+"_prefix",
		true,
		prefix,
	)
	if err != nil {
		return nil, err
	}

	// Add to our watch set
	ws.Add(iter.WatchCh())

	// Results go into two buckets
	result := make([][]*vagrant_server.ConfigVar, 2)
	const (
		idxAny = 0
		idxId  = 1
	)

	// Go through the iterator and accumulate the results
	b := dbTxn.Bucket(configBucket)
	for {
		current := iter.Next()
		if current == nil {
			break
		}
		record := current.(*configIndexRecord)

		idx := -1
		switch ref := record.RunnerRef.Target.(type) {
		case *vagrant_server.Ref_Runner_Any:
			idx = idxAny

		case *vagrant_server.Ref_Runner_Id:
			idx = idxId

			// We need to match this ID
			if ref.Id.Id != req.Id {
				continue
			}

		default:
			return nil, fmt.Errorf("config has unknown target type: %T", record.RunnerRef.Target)
		}

		var value vagrant_server.ConfigVar
		if err := dbGet(b, []byte(record.Id), &value); err != nil {
			return nil, err
		}

		result[idx] = append(result[idx], &value)
	}

	return result, nil
}

// configIndexSet writes an index record for a single config var.
func (s *State) configIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.ConfigVar) error {
	var project, application string
	var runner *vagrant_server.Ref_Runner
	switch scope := value.Scope.(type) {
	//TODO(spox): Does this need to be machine? Need basis too?
	//case *vagrant_server.ConfigVar_Application:

	case *vagrant_server.ConfigVar_Project:
		project = scope.Project.ResourceId

	case *vagrant_server.ConfigVar_Runner:
		runner = scope.Runner

	default:
		panic("unknown scope")
	}

	record := &configIndexRecord{
		Id:          string(id),
		Project:     project,
		Application: application,
		Name:        value.Name,
		Runner:      runner != nil,
		RunnerRef:   runner,
	}

	// If we have no value, we delete from the memdb index
	if value.Value == "" {
		return txn.Delete(configIndexTableName, record)
	}

	// Insert the index
	return txn.Insert(configIndexTableName, record)
}

// configIndexInit initializes the config index from persisted data.
func (s *State) configIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(configBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.ConfigVar
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.configIndexSet(memTxn, k, &value); err != nil {
			return err
		}

		return nil
	})
}

func (s *State) configVarId(v *vagrant_server.ConfigVar) []byte {
	switch scope := v.Scope.(type) {
	// TODO(spox): same as above with machine/basis/etc
	//case *vagrant_server.ConfigVar_Application:

	case *vagrant_server.ConfigVar_Project:
		return []byte(fmt.Sprintf("%s/%s/%s",
			scope.Project.ResourceId,
			"",
			v.Name,
		))

	case *vagrant_server.ConfigVar_Runner:
		var t string
		switch scope.Runner.Target.(type) {
		case *vagrant_server.Ref_Runner_Id:
			t = "by-id"

		case *vagrant_server.Ref_Runner_Any:
			t = "any"

		default:
			panic(fmt.Sprintf("unknown runner target scope: %T", scope.Runner.Target))
		}

		return []byte(fmt.Sprintf("runner/%s/%s", t, v.Name))

	default:
		panic("unknown scope")
	}
}

func configIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: configIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			configIndexIdIndexName: {
				Name:         configIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: true,
				},
			},

			configIndexProjectIndexName: {
				Name:         configIndexProjectIndexName,
				AllowMissing: true,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Project",
							Lowercase: true,
						},

						&memdb.StringFieldIndex{
							Field:     "Name",
							Lowercase: true,
						},
					},
				},
			},

			configIndexApplicationIndexName: {
				Name:         configIndexApplicationIndexName,
				AllowMissing: true,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Project",
							Lowercase: true,
						},

						&memdb.StringFieldIndex{
							Field:     "Application",
							Lowercase: true,
						},

						&memdb.StringFieldIndex{
							Field:     "Name",
							Lowercase: true,
						},
					},
				},
			},

			configIndexRunnerIndexName: {
				Name:         configIndexRunnerIndexName,
				AllowMissing: true,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.BoolFieldIndex{
							Field: "Runner",
						},

						&memdb.StringFieldIndex{
							Field:     "Name",
							Lowercase: true,
						},
					},
				},
			},
		},
	}
}

const (
	configIndexTableName            = "config-index"
	configIndexIdIndexName          = "id"
	configIndexProjectIndexName     = "project"
	configIndexApplicationIndexName = "application"
	configIndexRunnerIndexName      = "runner"
)

type configIndexRecord struct {
	Id          string
	Project     string
	Application string
	Name        string
	Runner      bool // true if this is a runner config
	RunnerRef   *vagrant_server.Ref_Runner
}
