package state

// TODO(spox): When dealing with the scopes on the configvar protos,
// we need to do lookups + fillins to populate parents so we index
// them correctly in memory and can properly do lookups

import (
	"errors"
	"fmt"
	"sort"

	"github.com/hashicorp/go-memdb"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serversort "github.com/hashicorp/vagrant/internal/server/sort"
	"gorm.io/gorm"
)

type Config struct {
	gorm.Model

	Cid   *string `gorm:"uniqueIndex"`
	Name  string
	Scope *ProtoValue // TODO(spox): polymorphic needs to allow for runner
	Value string
}

func init() {
	models = append(models, &Config{})
	dbIndexers = append(dbIndexers, (*State).configIndexInit)
	schemas = append(schemas, configIndexSchema)
}

func (c *Config) ToProto() *vagrant_server.ConfigVar {
	if c == nil {
		return nil
	}

	var config vagrant_server.ConfigVar
	if err := decode(c, &config); err != nil {
		panic("failed to decode config: " + err.Error())
	}

	return &config
}

func (s *State) ConfigFromProto(p *vagrant_server.ConfigVar) (*Config, error) {
	var c Config
	cid := string(s.configVarId(p))
	result := s.db.First(&c, &Config{Cid: &cid})
	if result.Error != nil {
		return nil, result.Error
	}

	return &c, nil
}

// ConfigSet writes a configuration variable to the data store.
func (s *State) ConfigSet(vs ...*vagrant_server.ConfigVar) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()
	var err error

	for _, v := range vs {
		if err := s.configSet(memTxn, v); err != nil {
			return err
		}
	}

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

	return s.configGetMerged(memTxn, ws, req)
}

func (s *State) configSet(
	memTxn *memdb.Txn,
	value *vagrant_server.ConfigVar,
) error {
	id := s.configVarId(value)

	// Persist the configuration in the db
	c, err := s.ConfigFromProto(value)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	if err != nil {
		cid := string(id)
		c = &Config{Cid: &cid}
	}

	if err = s.softDecode(value, c); err != nil {
		return saveErrorToStatus("config", err)
	}

	result := s.db.Save(c)
	if result.Error != nil {
		return saveErrorToStatus("config", result.Error)
	}

	// Create our index value and write that.
	if err = s.configIndexSet(memTxn, id, value); err != nil {
		return saveErrorToStatus("config", err)
	}

	return nil
}

func (s *State) configGetMerged(
	memTxn *memdb.Txn,
	ws memdb.WatchSet,
	req *vagrant_server.ConfigGetRequest,
) ([]*vagrant_server.ConfigVar, error) {
	var mergeSet [][]*vagrant_server.ConfigVar
	switch scope := req.Scope.(type) {
	case *vagrant_server.ConfigGetRequest_Basis:
		// For basis scope, we just return the basis scoped values
		return s.configGetExact(memTxn, ws, scope.Basis, req.Prefix)
	case *vagrant_server.ConfigGetRequest_Project:
		// For project scope, we collect project and basis values
		m, err := s.configGetExact(memTxn, ws, scope.Project.Basis, req.Prefix)
		if err != nil {
			return nil, err
		}
		mergeSet = append(mergeSet, m)
		m, err = s.configGetExact(memTxn, ws, scope.Project, req.Prefix)
		if err != nil {
			return nil, err
		}
		mergeSet = append(mergeSet, m)
	case *vagrant_server.ConfigGetRequest_Target:
		// For project scope, we collect project and basis values
		m, err := s.configGetExact(memTxn, ws, scope.Target.Project.Basis, req.Prefix)
		if err != nil {
			return nil, err
		}
		mergeSet = append(mergeSet, m)
		m, err = s.configGetExact(memTxn, ws, scope.Target.Project, req.Prefix)
		if err != nil {
			return nil, err
		}
		mergeSet = append(mergeSet, m)
		m, err = s.configGetExact(memTxn, ws, scope.Target, req.Prefix)
		if err != nil {
			return nil, err
		}
		mergeSet = append(mergeSet, m)
	case *vagrant_server.ConfigGetRequest_Runner:
		var err error
		mergeSet, err = s.configGetRunner(memTxn, ws, scope.Runner, req.Prefix)
		if err != nil {
			return nil, err
		}

	default:
		return nil, fmt.Errorf("unknown scope type provided (%T)", req.Scope)
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
// target-scoped variables, you'll get target-scoped variables. If a project-scoped
// variable matches, it will not be merged in.
func (s *State) configGetExact(
	memTxn *memdb.Txn,
	ws memdb.WatchSet,
	ref interface{}, // should be one of the *vagrant_plugin_sdk.Ref_ or *vagrant_server.Ref_ values.
	prefix string,
) ([]*vagrant_server.ConfigVar, error) {
	// We have to get the correct iterator based on the scope. We check the
	// scope and use the proper index to get the iterator here.
	var iter memdb.ResultIterator
	var err error
	switch v := ref.(type) {
	case *vagrant_plugin_sdk.Ref_Basis:
		iter, err = memTxn.Get(
			configIndexTableName,
			configIndexIdIndexName+"_prefix", // Enable a prefix match on lookup
			fmt.Sprintf("%s/%s", v.ResourceId, prefix),
		)
		if err != nil {
			return nil, err
		}
	case *vagrant_plugin_sdk.Ref_Project:
		iter, err = memTxn.Get(
			configIndexTableName,
			configIndexIdIndexName+"_prefix", // Enable a prefix match on lookup
			fmt.Sprintf("%s/%s/%s", v.Basis.ResourceId, v.ResourceId, prefix),
		)
		if err != nil {
			return nil, err
		}
	case *vagrant_plugin_sdk.Ref_Target:
		iter, err = memTxn.Get(
			configIndexTableName,
			configIndexIdIndexName+"_prefix", // Enable a prefix match on lookup
			fmt.Sprintf("%s/%s/%s/%s",
				v.Project.Basis.ResourceId,
				v.Project.ResourceId,
				v.ResourceId,
				prefix,
			),
		)
		if err != nil {
			return nil, err
		}

	default:
		return nil, fmt.Errorf("unknown scope type provided (%T)", ref)
	}

	// Add to our watchset
	ws.Add(iter.WatchCh())

	// Go through the iterator and accumulate the results
	var result []*vagrant_server.ConfigVar

	for {
		current := iter.Next()
		if current == nil {
			break
		}

		var value Config
		record := current.(*configIndexRecord)
		res := s.db.First(&value, &Config{Cid: &record.Id})
		if res.Error != nil {
			return nil, res.Error
		}
		result = append(result, value.ToProto())
	}

	return result, nil
}

// configGetRunner gets the config vars for a runner.
func (s *State) configGetRunner(
	memTxn *memdb.Txn,
	ws memdb.WatchSet,
	req *vagrant_server.Ref_RunnerId,
	prefix string,
) ([][]*vagrant_server.ConfigVar, error) {
	iter, err := memTxn.Get(
		configIndexTableName,
		configIndexRunnerIndexName+"_prefix", // Enable a prefix match on lookup
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

		var value Config
		res := s.db.First(&value, &Config{Cid: &record.Id})
		if res.Error != nil {
			return nil, res.Error
		}

		result[idx] = append(result[idx], value.ToProto())
	}

	return result, nil
}

// configIndexSet writes an index record for a single config var.
func (s *State) configIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.ConfigVar) error {
	var basis, project, target string
	var runner *vagrant_server.Ref_Runner
	switch scope := value.Scope.(type) {
	case *vagrant_server.ConfigVar_Basis:
		basis = scope.Basis.ResourceId
	case *vagrant_server.ConfigVar_Project:
		project = scope.Project.ResourceId
	case *vagrant_server.ConfigVar_Target:
		target = scope.Target.ResourceId
	case *vagrant_server.ConfigVar_Runner:
		runner = scope.Runner
	default:
		panic("unknown scope")
	}

	record := &configIndexRecord{
		Id:        string(id),
		Basis:     basis,
		Project:   project,
		Target:    target,
		Name:      value.Name,
		Runner:    runner != nil,
		RunnerRef: runner,
	}

	// If we have no value, we delete from the memdb index
	if value.Value == "" {
		return txn.Delete(configIndexTableName, record)
	}

	// Insert the index
	return txn.Insert(configIndexTableName, record)
}

// configIndexInit initializes the config index from persisted data.
func (s *State) configIndexInit(memTxn *memdb.Txn) error {
	var cfgs []Config
	result := s.db.Find(&cfgs)
	if result.Error != nil {
		return result.Error
	}
	for _, c := range cfgs {
		p := c.ToProto()
		if err := s.configIndexSet(memTxn, s.configVarId(p), p); err != nil {
			return err
		}
	}

	return nil
}

func (s *State) configVarId(v *vagrant_server.ConfigVar) []byte {
	switch scope := v.Scope.(type) {
	case *vagrant_server.ConfigVar_Basis:
		return []byte(
			fmt.Sprintf("%v/%v",
				scope.Basis.Name,
				v.Name,
			),
		)
	case *vagrant_server.ConfigVar_Project:
		return []byte(
			fmt.Sprintf("%v/%v/%v",
				scope.Project.Basis.ResourceId,
				scope.Project.ResourceId,
				v.Name,
			),
		)
	case *vagrant_server.ConfigVar_Target:
		return []byte(
			fmt.Sprintf("%v/%v/%v/%v",
				scope.Target.Project.Basis.ResourceId,
				scope.Target.Project.ResourceId,
				scope.Target.ResourceId,
				v.Name,
			),
		)
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
					Lowercase: false,
				},
			},

			configIndexBasisIndexName: {
				Name:         configIndexBasisIndexName,
				AllowMissing: true,
				Unique:       false,
				Indexer: &memdb.CompoundIndex{
					Indexes: []memdb.Indexer{
						&memdb.StringFieldIndex{
							Field:     "Basis",
							Lowercase: true,
						},

						&memdb.StringFieldIndex{
							Field:     "Name",
							Lowercase: true,
						},
					},
				},
			},

			configIndexProjectIndexName: {
				Name:         configIndexProjectIndexName,
				AllowMissing: true,
				Unique:       false,
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
							Field:     "Name",
							Lowercase: true,
						},
					},
				},
			},

			configIndexTargetIndexName: {
				Name:         configIndexTargetIndexName,
				AllowMissing: true,
				Unique:       false,
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
							Field:     "Target",
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
	configIndexTableName        = "config-index"
	configIndexIdIndexName      = "id"
	configIndexBasisIndexName   = "basis"
	configIndexProjectIndexName = "project"
	configIndexTargetIndexName  = "target"
	configIndexRunnerIndexName  = "runner"
)

type configIndexRecord struct {
	Id        string
	Basis     string
	Project   string
	Target    string
	Name      string
	Runner    bool // true if this is a runner config
	RunnerRef *vagrant_server.Ref_Runner
}
