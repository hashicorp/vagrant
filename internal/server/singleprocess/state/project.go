package state

import (
	"strings"

	"google.golang.org/protobuf/proto"
	"github.com/hashicorp/go-memdb"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

var projectBucket = []byte("project")

func init() {
	dbBuckets = append(dbBuckets, projectBucket)
	dbIndexers = append(dbIndexers, (*State).projectIndexInit)
	schemas = append(schemas, projectIndexSchema)
}

// ProjectPut creates or updates the given project.
func (s *State) ProjectPut(p *vagrant_server.Project) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) (err error) {
		return s.projectPut(dbTxn, memTxn, p)
	})

	if err == nil {
		memTxn.Commit()
	}

	return err
}

func (s *State) ProjectFind(p *vagrant_server.Project) (*vagrant_server.Project, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Project
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.projectFind(dbTxn, memTxn, p)
		return err
	})

	return result, err
}

// ProjectGet gets a project by reference.
func (s *State) ProjectGet(ref *vagrant_plugin_sdk.Ref_Project) (*vagrant_server.Project, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Project
	err := s.db.View(func(dbTxn *bolt.Tx) (err error) {
		result, err = s.projectGet(dbTxn, memTxn, ref)
		return err
	})

	return result, err
}

// ProjectDelete deletes a project by reference. This is a complete data
// delete. This will delete all operations associated with this project
// as well.
func (s *State) ProjectDelete(ref *vagrant_plugin_sdk.Ref_Project) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		// Now remove the project
		return s.projectDelete(dbTxn, memTxn, ref)
	})

	if err == nil {
		memTxn.Commit()
	}

	return err
}

// ProjectList returns the list of projects.
func (s *State) ProjectList() ([]*vagrant_plugin_sdk.Ref_Project, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	return s.projectList(memTxn)
}

func (s *State) projectFind(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	p *vagrant_server.Project,
) (*vagrant_server.Project, error) {
	var match *projectIndexRecord

	// Start with the resource id first
	if p.ResourceId != "" {
		if raw, err := memTxn.First(
			projectIndexTableName,
			projectIndexIdIndexName,
			p.ResourceId,
		); raw != nil && err == nil {
			match = raw.(*projectIndexRecord)
		}
	}
	// Try the name next
	if p.Name != "" && match == nil {
		if raw, err := memTxn.First(
			projectIndexTableName,
			projectIndexNameIndexName,
			p.Name,
		); raw != nil && err == nil {
			match = raw.(*projectIndexRecord)
		}
	}
	// And finally the path
	if p.Path != "" && match == nil {
		if raw, err := memTxn.First(
			projectIndexTableName,
			projectIndexPathIndexName,
			p.Path,
		); raw != nil && err == nil {
			match = raw.(*projectIndexRecord)
		}
	}

	if match == nil {
		return nil, status.Errorf(codes.NotFound, "record not found for Project")
	}

	return s.projectGet(dbTxn, memTxn, &vagrant_plugin_sdk.Ref_Project{
		ResourceId: match.Id,
	})
}

func (s *State) projectPut(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	value *vagrant_server.Project,
) (err error) {
	s.log.Trace("storing project", "project", value, "basis", value.Basis)

	// Grab the stored project if it's available
	existProject, err := s.projectFind(dbTxn, memTxn, value)
	if err != nil {
		// ensure value is nil to identify non-existence
		existProject = nil
	}

	// Grab the basis associated to this project so it can be attached
	b, err := s.basisGet(dbTxn, memTxn, value.Basis)
	if err != nil {
		s.log.Error("failed to locate basis for project", "project", value,
			"basis", value.Basis, "error", err)
		return
	}

	// set a resource id if none set
	if value.ResourceId == "" {
		s.log.Trace("project has no resource id, assuming new project",
			"project", value)
		if value.ResourceId, err = s.newResourceId(); err != nil {
			s.log.Error("failed to create resource id for project", "project", value,
				"error", err)
			return
		}
	}

	s.log.Trace("storing project to db", "project", value)
	id := s.projectId(value)
	// Get the global bucket and write the value to it.
	bkt := dbTxn.Bucket(projectBucket)
	if err = dbPut(bkt, id, value); err != nil {
		s.log.Error("failed to store project in db", "project", value, "error", err)
		return
	}

	s.log.Trace("indexing project", "project", value)
	// Create our index value and write that.
	if err = s.projectIndexSet(memTxn, id, value); err != nil {
		s.log.Error("failed to index project", "project", value, "error", err)
		return
	}

	s.log.Trace("adding project to basis", "project", value, "basis", b)
	nb := &serverptypes.Basis{Basis: b}
	if nb.AddProject(value) {
		s.log.Trace("project added to basis, updating basis", "basis", b)
		if err = s.basisPut(dbTxn, memTxn, b); err != nil {
			s.log.Error("failed to update basis", "basis", b, "error", err)
			return
		}
	} else {
		s.log.Trace("project already exists in basis", "project", value, "basis", b)
	}

	// Check if the project basis was changed
	if existProject != nil && existProject.Basis.ResourceId != b.ResourceId {
		s.log.Trace("project basis has changed, updating old basis", "project", value,
			"old-basis", existProject.Basis, "new-basis", value.Basis)
		ob, err := s.basisGet(dbTxn, memTxn, existProject.Basis)
		if err != nil {
			s.log.Warn("failed to locate old basis, ignoring", "project", value, "old-basis",
				existProject.Basis, "error", err)
			return nil
		}
		bt := &serverptypes.Basis{Basis: ob}
		if bt.DeleteProject(value) {
			s.log.Trace("project deleted from old basis, updating basis", "project", value,
				"old-basis", ob)
			if err := s.basisPut(dbTxn, memTxn, ob); err != nil {
				s.log.Error("failed to updated old basis for project removal", "project", value,
					"old-basis", ob, "error", err)
			}
		}
	}

	return
}

func (s *State) projectGet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Project,
) (*vagrant_server.Project, error) {
	var result vagrant_server.Project
	b := dbTxn.Bucket(projectBucket)
	return &result, dbGet(b, s.projectIdByRef(ref), &result)
}

func (s *State) projectList(
	memTxn *memdb.Txn,
) ([]*vagrant_plugin_sdk.Ref_Project, error) {
	iter, err := memTxn.Get(projectIndexTableName, projectIndexIdIndexName+"_prefix", "")
	if err != nil {
		return nil, err
	}

	var result []*vagrant_plugin_sdk.Ref_Project
	for {
		next := iter.Next()
		if next == nil {
			break
		}
		idx := next.(*projectIndexRecord)

		result = append(result, &vagrant_plugin_sdk.Ref_Project{
			ResourceId: idx.Id,
			Name:       idx.Name,
		})
	}

	return result, nil
}

func (s *State) projectDelete(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Project,
) (err error) {
	p, err := s.projectGet(dbTxn, memTxn, ref)
	if err != nil {
		return
	}

	// Start with scrubbing all the machines
	for _, m := range p.Targets {
		if err = s.targetDelete(dbTxn, memTxn, m); err != nil {
			return
		}
	}

	// Grab the basis and remove the project
	b, err := s.basisGet(dbTxn, memTxn, ref.Basis)
	if err != nil {
		return
	}
	bp := &serverptypes.Basis{Basis: b}
	if bp.DeleteProjectRef(ref) {
		err = s.basisPut(dbTxn, memTxn, b)
	}

	// Delete from bolt
	if err := dbTxn.Bucket(projectBucket).Delete(s.projectId(p)); err != nil {
		return err
	}

	// Delete from memdb
	if err := memTxn.Delete(projectIndexTableName, s.newProjectIndexRecord(p)); err != nil {
		return err
	}

	return
}

// projectIndexSet writes an index record for a single project.
func (s *State) projectIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.Project) error {
	return txn.Insert(projectIndexTableName, s.newProjectIndexRecord(value))
}

// projectIndexInit initializes the project index from persisted data.
func (s *State) projectIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(projectBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.Project
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.projectIndexSet(memTxn, k, &value); err != nil {
			return err
		}

		return nil
	})
}

func projectIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: projectIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			projectIndexIdIndexName: {
				Name:         projectIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: false,
				},
			},
			projectIndexNameIndexName: {
				Name:         projectIndexNameIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Name",
					Lowercase: true,
				},
			},
			projectIndexPathIndexName: {
				Name:         projectIndexPathIndexName,
				AllowMissing: true,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Path",
					Lowercase: false,
				},
			},
		},
	}
}

const (
	projectIndexIdIndexName   = "id"
	projectIndexNameIndexName = "name"
	projectIndexPathIndexName = "path"
	projectIndexTableName     = "project-index"
)

type projectIndexRecord struct {
	Id   string
	Name string
	Path string
}

func (s *State) newProjectIndexRecord(p *vagrant_server.Project) *projectIndexRecord {
	return &projectIndexRecord{
		Id:   p.ResourceId,
		Name: strings.ToLower(p.Name),
		Path: p.Path,
	}
}

func (s *State) newProjectIndexRecordByRef(ref *vagrant_plugin_sdk.Ref_Project) *projectIndexRecord {
	return &projectIndexRecord{
		Id:   ref.ResourceId,
		Name: strings.ToLower(ref.Name),
	}
}

func (s *State) projectId(p *vagrant_server.Project) []byte {
	return []byte(p.ResourceId)
}

func (s *State) projectIdByRef(ref *vagrant_plugin_sdk.Ref_Project) []byte {
	if ref == nil {
		return []byte{}
	}
	return []byte(ref.ResourceId)
}
