package state

import (
	"github.com/google/uuid"
	"github.com/hashicorp/go-memdb"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

var targetBucket = []byte("target")

func init() {
	dbBuckets = append(dbBuckets, targetBucket)
	dbIndexers = append(dbIndexers, (*State).targetIndexInit)
	schemas = append(schemas, targetIndexSchema)
}

func (s *State) TargetFind(m *vagrant_server.Target) (*vagrant_server.Target, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Target
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.targetFind(dbTxn, memTxn, m)
		return err
	})

	return result, err
}

func (s *State) TargetPut(target *vagrant_server.Target) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.targetPut(dbTxn, memTxn, target)
	})
	if err == nil {
		memTxn.Commit()
	}
	return err
}

func (s *State) TargetDelete(ref *vagrant_plugin_sdk.Ref_Target) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.targetDelete(dbTxn, memTxn, ref)
	})
	if err == nil {
		memTxn.Commit()
	}

	return err
}

func (s *State) TargetGet(ref *vagrant_plugin_sdk.Ref_Target) (*vagrant_server.Target, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Target
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.targetGet(dbTxn, memTxn, ref)
		return err
	})

	return result, err
}

func (s *State) TargetList() ([]*vagrant_plugin_sdk.Ref_Target, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	return s.targetList(memTxn)
}

func (s *State) targetFind(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	m *vagrant_server.Target,
) (*vagrant_server.Target, error) {
	var match *targetIndexRecord
	req := s.newTargetIndexRecord(m)

	// Start with the resource id first
	if req.Id != "" {
		if raw, err := memTxn.First(
			targetIndexTableName,
			targetIndexIdIndexName,
			req.Id,
		); raw != nil && err == nil {
			match = raw.(*targetIndexRecord)
		}
	}
	// Try the name + project next
	if match == nil && req.Name != "" {
		// Match the name first
		raw, err := memTxn.Get(
			targetIndexTableName,
			targetIndexNameIndexName,
			req.Name,
		)
		if err != nil {
			return nil, err
		}
		// Check for matching project next
		if req.ProjectId != "" {
			for e := raw.Next(); e != nil; e = raw.Next() {
				targetIndexEntry := e.(*targetIndexRecord)
				if targetIndexEntry.ProjectId == req.ProjectId {
					match = targetIndexEntry
					break
				}
			}
		} else {
			e := raw.Next()
			if e != nil {
				match = e.(*targetIndexRecord)
			}
		}
	}
	// Finally try the uuid
	if match == nil && req.Uuid != "" {
		if raw, err := memTxn.First(
			targetIndexTableName,
			targetIndexUuidName,
			req.Uuid,
		); raw != nil && err == nil {
			match = raw.(*targetIndexRecord)
		}
	}

	if match == nil {
		return nil, status.Errorf(codes.NotFound, "record not found for Target (name: %s resource_id: %s)", m.Name, m.ResourceId)
	}

	return s.targetGet(dbTxn, memTxn, &vagrant_plugin_sdk.Ref_Target{
		ResourceId: match.Id,
	})
}

func (s *State) targetList(
	memTxn *memdb.Txn,
) ([]*vagrant_plugin_sdk.Ref_Target, error) {
	iter, err := memTxn.Get(targetIndexTableName, targetIndexIdIndexName+"_prefix", "")
	if err != nil {
		return nil, err
	}

	var result []*vagrant_plugin_sdk.Ref_Target
	for {
		next := iter.Next()
		if next == nil {
			break
		}
		result = append(result, &vagrant_plugin_sdk.Ref_Target{
			ResourceId: next.(*targetIndexRecord).Id,
			Name:       next.(*targetIndexRecord).Name,
			Project: &vagrant_plugin_sdk.Ref_Project{
				ResourceId: next.(*targetIndexRecord).ProjectId,
			},
		})
	}

	return result, nil
}

func (s *State) targetPut(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	value *vagrant_server.Target,
) (err error) {
	s.log.Trace("storing target", "target", value, "project",
		value.GetProject(), "basis", value.GetProject().GetBasis())

	p, err := s.projectGet(dbTxn, memTxn, value.Project)
	if err != nil {
		s.log.Error("failed to locate project for target", "target", value,
			"project", p, "error", err)
		return
	}

	if value.ResourceId == "" {
		// If no resource id is provided, try to find the target based on the name and project
		foundTarget, erro := s.targetFind(dbTxn, memTxn, value)
		// If an invalid return code is returned from find then an error occured
		if _, ok := status.FromError(erro); !ok {
			return erro
		}
		if foundTarget != nil {
			// Make sure the config doesn't get merged - we want the config to overwrite the old config
			finalConfig := proto.Clone(value.Configuration)
			// Merge found target with provided target
			proto.Merge(value, foundTarget)
			value.ResourceId = foundTarget.ResourceId
			value.Uuid = foundTarget.Uuid
			value.Configuration = finalConfig.(*vagrant_plugin_sdk.Args_ConfigData)
		} else {
			s.log.Trace("target has no resource id and could not find matching target, assuming new target",
				"target", value)
			if value.ResourceId, err = s.newResourceId(); err != nil {
				s.log.Error("failed to create resource id for target", "target", value,
					"error", err)
				return
			}
		}
		if value.Uuid == "" {
			s.log.Trace("target has no uuid assigned, assigning...", "target", value)
			uID, err := uuid.NewUUID()
			if err != nil {
				return err
			}
			value.Uuid = uID.String()
		}

	}

	s.log.Trace("storing target to db", "target", value)
	id := s.targetId(value)
	b := dbTxn.Bucket(targetBucket)
	if err = dbPut(b, id, value); err != nil {
		s.log.Error("failed to store target in db", "target", value, "error", err)
		return
	}

	s.log.Trace("indexing target", "target", value)
	if err = s.targetIndexSet(memTxn, id, value); err != nil {
		s.log.Error("failed to index target", "target", value, "error", err)
		return
	}

	s.log.Trace("adding target to project", "target", value, "project", p)
	pp := serverptypes.Project{Project: p}
	if pp.AddTarget(value) {
		s.log.Trace("target added to project, updating project", "project", p)
		if err = s.projectPut(dbTxn, memTxn, p); err != nil {
			s.log.Error("failed to update project", "project", p, "error", err)
			return
		}
	} else {
		s.log.Trace("target already exists in project", "target", value, "project", p)
	}

	return
}

func (s *State) targetGet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Target,
) (*vagrant_server.Target, error) {
	var result vagrant_server.Target
	b := dbTxn.Bucket(targetBucket)
	return &result, dbGet(b, s.targetIdByRef(ref), &result)
}

func (s *State) targetDelete(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Target,
) (err error) {
	p, err := s.projectGet(dbTxn, memTxn, &vagrant_plugin_sdk.Ref_Project{ResourceId: ref.Project.ResourceId})
	if err != nil {
		return
	}

	if err = dbTxn.Bucket(targetBucket).Delete(s.targetIdByRef(ref)); err != nil {
		return
	}
	if err = memTxn.Delete(targetIndexTableName, s.newTargetIndexRecordByRef(ref)); err != nil {
		return
	}

	pp := serverptypes.Project{Project: p}
	if pp.DeleteTargetRef(ref) {
		if err = s.projectPut(dbTxn, memTxn, p); err != nil {
			return
		}
	}
	return
}

func (s *State) targetIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.Target) error {
	return txn.Insert(targetIndexTableName, s.newTargetIndexRecord(value))
}

func (s *State) targetIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(targetBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.Target
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.targetIndexSet(memTxn, k, &value); err != nil {
			return err
		}

		return nil
	})
}

func targetIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: targetIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			targetIndexIdIndexName: {
				Name:         targetIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: false,
				},
			},
			targetIndexNameIndexName: {
				Name:         targetIndexNameIndexName,
				AllowMissing: false,
				Unique:       false,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Name",
					Lowercase: true,
				},
			},
			targetIndexProjectIndexName: {
				Name:         targetIndexProjectIndexName,
				AllowMissing: false,
				Unique:       false,
				Indexer: &memdb.StringFieldIndex{
					Field:     "ProjectId",
					Lowercase: true,
				},
			},
			targetIndexUuidName: {
				Name:         targetIndexUuidName,
				AllowMissing: true,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Uuid",
					Lowercase: true,
				},
			},
		},
	}
}

const (
	targetIndexIdIndexName      = "id"
	targetIndexNameIndexName    = "name"
	targetIndexProjectIndexName = "project"
	targetIndexUuidName         = "uuid"
	targetIndexTableName        = "target-index"
)

type targetIndexRecord struct {
	Id        string // Resource ID
	Name      string // Target Name
	ProjectId string // Project Resource ID
	Uuid      string // Target UUID
}

func (s *State) newTargetIndexRecord(m *vagrant_server.Target) *targetIndexRecord {
	var projectResourceId string
	if m.Project != nil {
		projectResourceId = m.Project.ResourceId
	}
	i := &targetIndexRecord{
		Id:        m.ResourceId,
		Name:      m.Name,
		ProjectId: projectResourceId,
		Uuid:      m.Uuid,
	}
	return i
}

func (s *State) newTargetIndexRecordByRef(ref *vagrant_plugin_sdk.Ref_Target) *targetIndexRecord {
	var projectResourceId string
	if ref.Project != nil {
		projectResourceId = ref.Project.ResourceId
	}
	return &targetIndexRecord{
		Id:        ref.ResourceId,
		Name:      ref.Name,
		ProjectId: projectResourceId,
	}
}

func (s *State) targetId(m *vagrant_server.Target) []byte {
	return []byte(m.ResourceId)
}

func (s *State) targetIdByRef(m *vagrant_plugin_sdk.Ref_Target) []byte {
	return []byte(m.ResourceId)
}
