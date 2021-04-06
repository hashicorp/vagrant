package state

import (
	"strings"

	"github.com/boltdb/bolt"
	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/go-memdb"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

var machineBucket = []byte("machine")

func init() {
	dbBuckets = append(dbBuckets, machineBucket)
	dbIndexers = append(dbIndexers, (*State).machineIndexInit)
	schemas = append(schemas, machineIndexSchema)
}

func (s *State) MachineFind(m *vagrant_server.Machine) (*vagrant_server.Machine, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Machine
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.machineFind(dbTxn, memTxn, m)
		return err
	})

	return result, err
}

func (s *State) MachinePut(machine *vagrant_server.Machine) (*vagrant_server.Machine, error) {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.machinePut(dbTxn, memTxn, machine)
	})
	if err == nil {
		memTxn.Commit()
	}
	return machine, err
}

func (s *State) MachineDelete(ref *vagrant_server.Ref_Machine) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.machineDelete(dbTxn, memTxn, ref)
	})
	if err == nil {
		memTxn.Commit()
	}

	return err
}

func (s *State) MachineGet(ref *vagrant_server.Ref_Machine) (*vagrant_server.Machine, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Machine
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.machineGet(dbTxn, memTxn, ref)
		return err
	})

	return result, err
}

func (s *State) MachineList() ([]*vagrant_server.Ref_Machine, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	return s.machineList(memTxn)
}

func (s *State) machineFind(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	m *vagrant_server.Machine,
) (*vagrant_server.Machine, error) {
	var match *machineIndexRecord
	req := s.newMachineIndexRecord(m)

	// Start with the resource id first
	if req.Id != "" {
		if raw, err := memTxn.First(
			machineIndexTableName,
			machineIndexIdIndexName,
			req.Id,
		); raw != nil && err == nil {
			match = raw.(*machineIndexRecord)
		}
	}
	// Try the name next
	if match == nil && req.Name != "" {
		if raw, err := memTxn.First(
			machineIndexTableName,
			machineIndexNameIndexName,
			req.Name,
		); raw != nil && err == nil {
			match = raw.(*machineIndexRecord)
		}
	}
	// Finally try the machine id
	if match == nil && req.MachineId != "" {
		if raw, err := memTxn.First(
			machineIndexTableName,
			machineIndexMachineIdIndexName,
			req.MachineId,
		); raw != nil && err == nil {
			match = raw.(*machineIndexRecord)
		}
	}

	if match == nil {
		return nil, status.Errorf(codes.NotFound, "record not found for Machine")
	}

	return s.machineGet(dbTxn, memTxn, &vagrant_server.Ref_Machine{
		ResourceId: match.Id,
	})
}

func (s *State) machineList(
	memTxn *memdb.Txn,
) ([]*vagrant_server.Ref_Machine, error) {
	iter, err := memTxn.Get(machineIndexTableName, machineIndexIdIndexName+"_prefix", "")
	if err != nil {
		return nil, err
	}

	var result []*vagrant_server.Ref_Machine
	for {
		next := iter.Next()
		if next == nil {
			break
		}
		result = append(result, &vagrant_server.Ref_Machine{
			ResourceId: next.(*machineIndexRecord).Id,
			Name:       next.(*machineIndexRecord).Name,
		})
	}

	return result, nil
}

func (s *State) machinePut(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	value *vagrant_server.Machine,
) (err error) {
	s.log.Trace("storing machine", "machine", value, "project",
		value.Project, "basis", value.Project.Basis)

	p, err := s.projectGet(dbTxn, memTxn, value.Project)
	if err != nil {
		s.log.Error("failed to locate project for machine", "machine", value,
			"project", p, "error", err)
		return
	}

	if value.ResourceId == "" {
		s.log.Trace("machine has no resource id, assuming new machine",
			"machine", value)
		if value.ResourceId, err = s.newResourceId(); err != nil {
			s.log.Error("failed to create resource id for machine", "machine", value,
				"error", err)
			return
		}
	}

	s.log.Trace("storing machine to db", "machine", value)
	id := s.machineId(value)
	b := dbTxn.Bucket(machineBucket)
	if err = dbPut(b, id, value); err != nil {
		s.log.Error("failed to store machine in db", "machine", value, "error", err)
		return
	}

	s.log.Trace("indexing machine", "machine", value)
	if err = s.machineIndexSet(memTxn, id, value); err != nil {
		s.log.Error("failed to index machine", "machine", value, "error", err)
		return
	}

	s.log.Trace("adding machine to project", "machine", value, "project", p)
	pp := serverptypes.Project{Project: p}
	if pp.AddMachine(value) {
		s.log.Trace("machine added to project, updating project", "project", p)
		if err = s.projectPut(dbTxn, memTxn, p); err != nil {
			s.log.Error("failed to update project", "project", p, "error", err)
			return
		}
	} else {
		s.log.Trace("machine already exists in project", "machine", value, "project", p)
	}

	return
}

func (s *State) machineGet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_server.Ref_Machine,
) (*vagrant_server.Machine, error) {
	var result vagrant_server.Machine
	b := dbTxn.Bucket(machineBucket)
	return &result, dbGet(b, s.machineIdByRef(ref), &result)
}

func (s *State) machineDelete(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_server.Ref_Machine,
) (err error) {
	p, err := s.projectGet(dbTxn, memTxn, &vagrant_server.Ref_Project{ResourceId: ref.Project.ResourceId})
	if err != nil {
		return
	}

	if err = dbTxn.Bucket(machineBucket).Delete(s.machineIdByRef(ref)); err != nil {
		return
	}
	if err = memTxn.Delete(machineIndexTableName, s.newMachineIndexRecordByRef(ref)); err != nil {
		return
	}

	pp := serverptypes.Project{Project: p}
	if pp.DeleteMachineRef(ref) {
		if err = s.projectPut(dbTxn, memTxn, p); err != nil {
			return
		}
	}
	return
}

func (s *State) machineIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.Machine) error {
	return txn.Insert(machineIndexTableName, s.newMachineIndexRecord(value))
}

func (s *State) machineIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(machineBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.Machine
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.machineIndexSet(memTxn, k, &value); err != nil {
			return err
		}

		return nil
	})
}

func machineIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: machineIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			machineIndexIdIndexName: {
				Name:         machineIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: false,
				},
			},
			machineIndexNameIndexName: {
				Name:         machineIndexNameIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Name",
					Lowercase: true,
				},
			},
			machineIndexMachineIdIndexName: {
				Name:         machineIndexMachineIdIndexName,
				AllowMissing: true,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "MachineId",
					Lowercase: false,
				},
			},
		},
	}
}

const (
	machineIndexIdIndexName        = "id"
	machineIndexNameIndexName      = "name"
	machineIndexMachineIdIndexName = "machine-id"
	machineIndexTableName          = "machine-index"
)

type machineIndexRecord struct {
	Id        string // Resource ID
	Name      string // Project Resource ID + Machine Name
	MachineId string // Project Resource ID + Machine ID (not machine resource id)
}

func (s *State) newMachineIndexRecord(m *vagrant_server.Machine) *machineIndexRecord {
	i := &machineIndexRecord{
		Id:   m.ResourceId,
		Name: strings.ToLower(m.Project.ResourceId + "+" + m.Name),
	}
	if m.Id != "" {
		i.MachineId = m.Project.ResourceId + "+" + m.Id
	}
	return i
}

func (s *State) newMachineIndexRecordByRef(ref *vagrant_server.Ref_Machine) *machineIndexRecord {
	return &machineIndexRecord{
		Id:   ref.ResourceId,
		Name: strings.ToLower(ref.Project.ResourceId + "+" + ref.Name),
	}
}

func (s *State) machineId(m *vagrant_server.Machine) []byte {
	return []byte(m.ResourceId)
}

func (s *State) machineIdByRef(m *vagrant_server.Ref_Machine) []byte {
	return []byte(m.ResourceId)
}
