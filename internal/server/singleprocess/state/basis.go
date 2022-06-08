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
)

var basisBucket = []byte("basis")

func init() {
	dbBuckets = append(dbBuckets, basisBucket)
	dbIndexers = append(dbIndexers, (*State).basisIndexInit)
	schemas = append(schemas, basisIndexSchema)
}

func (s *State) BasisFind(b *vagrant_server.Basis) (*vagrant_server.Basis, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Basis
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.basisFind(dbTxn, memTxn, b)
		return err
	})

	return result, err
}

func (s *State) BasisGet(ref *vagrant_plugin_sdk.Ref_Basis) (*vagrant_server.Basis, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Basis
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.basisGet(dbTxn, memTxn, ref)
		return err
	})

	return result, err
}

func (s *State) BasisPut(b *vagrant_server.Basis) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.basisPut(dbTxn, memTxn, b)
	})
	if err == nil {
		memTxn.Commit()
	}

	return err
}

func (s *State) BasisDelete(ref *vagrant_plugin_sdk.Ref_Basis) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.basisDelete(dbTxn, memTxn, ref)
	})

	if err == nil {
		memTxn.Commit()
	}

	return err
}

func (s *State) BasisList() ([]*vagrant_plugin_sdk.Ref_Basis, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	return s.basisList(memTxn)
}

func (s *State) basisGet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Basis,
) (*vagrant_server.Basis, error) {
	var result vagrant_server.Basis
	b := dbTxn.Bucket(basisBucket)
	return &result, dbGet(b, s.basisIdByRef(ref), &result)
}

func (s *State) basisFind(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	b *vagrant_server.Basis,
) (*vagrant_server.Basis, error) {
	var match *basisIndexRecord

	// Start with the resource id first
	if b.ResourceId != "" {
		if raw, err := memTxn.First(
			basisIndexTableName,
			basisIndexIdIndexName,
			b.ResourceId,
		); raw != nil && err == nil {
			match = raw.(*basisIndexRecord)
		}
	}
	// Try the name next
	if b.Name != "" && match == nil {
		if raw, err := memTxn.First(
			basisIndexTableName,
			basisIndexNameIndexName,
			b.Name,
		); raw != nil && err == nil {
			match = raw.(*basisIndexRecord)
		}
	}
	// And finally the path
	if b.Path != "" && match == nil {
		if raw, err := memTxn.First(
			basisIndexTableName,
			basisIndexPathIndexName,
			b.Path,
		); raw != nil && err == nil {
			match = raw.(*basisIndexRecord)
		}
	}

	if match == nil {
		return nil, status.Errorf(codes.NotFound, "record not found for Basis")
	}

	return s.basisGet(dbTxn, memTxn, &vagrant_plugin_sdk.Ref_Basis{
		ResourceId: match.Id,
	})
}

func (s *State) basisPut(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	value *vagrant_server.Basis,
) (err error) {
	s.log.Trace("storing basis", "basis", value)

	if value.ResourceId == "" {
		s.log.Trace("basis has no resource id, assuming new basis",
			"basis", value)
		if value.ResourceId, err = s.newResourceId(); err != nil {
			s.log.Error("failed to create resource id for basis", "basis", value,
				"error", err)
			return
		}
	}

	s.log.Trace("storing basis to db", "basis", value)
	id := s.basisId(value)
	b := dbTxn.Bucket(basisBucket)
	if err = dbPut(b, id, value); err != nil {
		s.log.Error("failed to store basis in db", "basis", value, "error", err)
		return
	}

	s.log.Trace("indexing basis", "basis", value)
	if err = s.basisIndexSet(memTxn, id, value); err != nil {
		s.log.Error("failed to index basis", "basis", value, "error", err)
		return
	}

	return
}

func (s *State) basisList(
	memTxn *memdb.Txn,
) ([]*vagrant_plugin_sdk.Ref_Basis, error) {
	iter, err := memTxn.Get(basisIndexTableName, basisIndexIdIndexName+"_prefix", "")
	if err != nil {
		return nil, err
	}

	var result []*vagrant_plugin_sdk.Ref_Basis
	for {
		next := iter.Next()
		if next == nil {
			break
		}
		idx := next.(*basisIndexRecord)

		result = append(result, &vagrant_plugin_sdk.Ref_Basis{
			ResourceId: idx.Id,
			Name:       idx.Name,
		})
	}

	return result, nil
}

func (s *State) basisDelete(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Basis,
) error {
	b, err := s.basisGet(dbTxn, memTxn, ref)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return nil
		}
		return err
	}

	for _, p := range b.Projects {
		if err := s.projectDelete(dbTxn, memTxn, p); err != nil {
			return err
		}
	}

	// Delete from bolt
	if err := dbTxn.Bucket(basisBucket).Delete(s.basisId(b)); err != nil {
		return err
	}
	// Delete from memdb
	record := s.newBasisIndexRecord(b)
	if err := memTxn.Delete(basisIndexTableName, record); err != nil {
		return err
	}
	return nil
}

func (s *State) basisIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.Basis) error {
	return txn.Insert(basisIndexTableName, s.newBasisIndexRecord(value))
}

func (s *State) basisIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(basisBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.Basis
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.basisIndexSet(memTxn, k, &value); err != nil {
			return err
		}

		return nil
	})
}

func basisIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: basisIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			basisIndexIdIndexName: {
				Name:         basisIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: false,
				},
			},
			basisIndexNameIndexName: {
				Name:         basisIndexNameIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Name",
					Lowercase: true,
				},
			},
			basisIndexPathIndexName: {
				Name:         basisIndexPathIndexName,
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
	basisIndexIdIndexName   = "id"
	basisIndexNameIndexName = "name"
	basisIndexPathIndexName = "path"
	basisIndexTableName     = "basis-index"
)

type basisIndexRecord struct {
	Id   string
	Name string
	Path string
}

func (s *State) newBasisIndexRecord(b *vagrant_server.Basis) *basisIndexRecord {
	return &basisIndexRecord{
		Id:   b.ResourceId,
		Name: strings.ToLower(b.Name),
		Path: b.Path,
	}
}

func (s *State) newBasisIndexRecordByRef(ref *vagrant_plugin_sdk.Ref_Basis) *basisIndexRecord {
	return &basisIndexRecord{
		Id:   ref.ResourceId,
		Name: strings.ToLower(ref.Name),
	}
}

func (s *State) basisId(b *vagrant_server.Basis) []byte {
	return []byte(b.ResourceId)
}

func (s *State) basisIdByRef(ref *vagrant_plugin_sdk.Ref_Basis) []byte {
	if ref == nil {
		return []byte{}
	}
	return []byte(ref.ResourceId)
}
