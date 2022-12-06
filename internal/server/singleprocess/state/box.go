package state

import (
	"google.golang.org/protobuf/proto"
	"github.com/hashicorp/go-memdb"
	"github.com/hashicorp/go-version"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var boxBucket = []byte("box")

func init() {
	dbBuckets = append(dbBuckets, boxBucket)
	dbIndexers = append(dbIndexers, (*State).boxIndexInit)
	schemas = append(schemas, boxIndexSchema)
}

func (s *State) BoxList() ([]*vagrant_plugin_sdk.Ref_Box, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	return s.boxList(memTxn)
}

func (s *State) BoxDelete(ref *vagrant_plugin_sdk.Ref_Box) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.boxDelete(dbTxn, memTxn, ref)
	})
	if err == nil {
		memTxn.Commit()
	}

	return err
}

func (s *State) BoxGet(ref *vagrant_plugin_sdk.Ref_Box) (*vagrant_server.Box, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Box
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.boxGet(dbTxn, memTxn, ref)
		return err
	})

	return result, err
}

func (s *State) BoxPut(box *vagrant_server.Box) error {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		return s.boxPut(dbTxn, memTxn, box)
	})
	if err == nil {
		memTxn.Commit()
	}
	return err
}

func (s *State) BoxFind(b *vagrant_plugin_sdk.Ref_Box) (*vagrant_server.Box, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()

	var result *vagrant_server.Box
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		var err error
		result, err = s.boxFind(dbTxn, memTxn, b)
		return err
	})

	return result, err
}

func (s *State) boxList(
	memTxn *memdb.Txn,
) (r []*vagrant_plugin_sdk.Ref_Box, err error) {
	iter, err := memTxn.Get(boxIndexTableName, boxIndexIdIndexName+"_prefix", "")
	if err != nil {
		return nil, err
	}

	var result []*vagrant_plugin_sdk.Ref_Box
	for {
		next := iter.Next()
		if next == nil {
			break
		}
		result = append(result, &vagrant_plugin_sdk.Ref_Box{
			ResourceId: next.(*boxIndexRecord).Id,
			Name:       next.(*boxIndexRecord).Name,
			Version:    next.(*boxIndexRecord).Version,
			Provider:   next.(*boxIndexRecord).Provider,
		})
	}

	return result, nil
}

func (s *State) boxDelete(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Box,
) (err error) {
	b, err := s.boxGet(dbTxn, memTxn, ref)
	if err != nil {
		if status.Code(err) == codes.NotFound {
			return nil
		}
		return err
	}
	// Delete the box
	if err = dbTxn.Bucket(boxBucket).Delete(s.boxId(b)); err != nil {
		return
	}
	if err = memTxn.Delete(boxIndexTableName, s.newBoxIndexRecord(b)); err != nil {
		return
	}
	return
}

func (s *State) boxGet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Box,
) (r *vagrant_server.Box, err error) {
	var result vagrant_server.Box
	b := dbTxn.Bucket(boxBucket)
	return &result, dbGet(b, s.boxIdByRef(ref), &result)
}

func (s *State) boxPut(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	value *vagrant_server.Box,
) (err error) {
	id := s.boxId(value)
	b := dbTxn.Bucket(boxBucket)
	if err = dbPut(b, id, value); err != nil {
		s.log.Error("failed to store box in db", "box", value, "error", err)
		return
	}

	s.log.Trace("indexing box", "box", value)
	if err = s.boxIndexSet(memTxn, id, value); err != nil {
		s.log.Error("failed to index box", "box", value, "error", err)
		return
	}

	return
}

func (s *State) boxFind(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	ref *vagrant_plugin_sdk.Ref_Box,
) (r *vagrant_server.Box, err error) {
	var match *boxIndexRecord
	highestVersion, _ := version.NewVersion("0.0.0")
	req := s.newBoxIndexRecordByRef(ref)
	// Get the name first
	if req.Name != "" {
		raw, err := memTxn.Get(
			boxIndexTableName,
			boxIndexNameIndexName,
			req.Name,
		)
		if err != nil {
			return nil, err
		}
		if req.Version == "" {
			req.Version = ">= 0"
		}
		versionConstraint, err := version.NewConstraint(req.Version)
		if err != nil {
			return nil, err
		}

		for e := raw.Next(); e != nil; e = raw.Next() {
			boxIndexEntry := e.(*boxIndexRecord)
			if req.Version != "" {
				boxVersion, _ := version.NewVersion(boxIndexEntry.Version)
				if !versionConstraint.Check(boxVersion) {
					continue
				}
			}
			if req.Provider != "" {
				if boxIndexEntry.Provider != req.Provider {
					continue
				}
			}
			// Set first match
			if match == nil {
				match = boxIndexEntry
			}
			v, _ := version.NewVersion(boxIndexEntry.Version)
			if v.GreaterThan(highestVersion) {
				highestVersion = v
				match = boxIndexEntry
			}
		}

		if match != nil {
			return s.boxGet(dbTxn, memTxn, &vagrant_plugin_sdk.Ref_Box{
				ResourceId: match.Id,
			})
		}
	}

	return
}

const (
	boxIndexIdIndexName   = "id"
	boxIndexNameIndexName = "name"
	boxIndexTableName     = "box-index"
)

type boxIndexRecord struct {
	Id       string // Resource ID
	Name     string // Box Name
	Version  string // Box Version
	Provider string // Box Provider
}

func (s *State) newBoxIndexRecord(b *vagrant_server.Box) *boxIndexRecord {
	id := b.Name + "-" + b.Version + "-" + b.Provider
	return &boxIndexRecord{
		Id:       id,
		Name:     b.Name,
		Version:  b.Version,
		Provider: b.Provider,
	}
}

func (s *State) boxIndexSet(txn *memdb.Txn, id []byte, value *vagrant_server.Box) error {
	return txn.Insert(boxIndexTableName, s.newBoxIndexRecord(value))
}

func (s *State) boxIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	bucket := dbTxn.Bucket(boxBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.Box
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.boxIndexSet(memTxn, k, &value); err != nil {
			return err
		}

		return nil
	})
}

func boxIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: boxIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			boxIndexIdIndexName: {
				Name:         boxIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: true,
				},
			},
			boxIndexNameIndexName: {
				Name:         boxIndexNameIndexName,
				AllowMissing: false,
				Unique:       false,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Name",
					Lowercase: true,
				},
			},
		},
	}
}

func (s *State) newBoxIndexRecordByRef(ref *vagrant_plugin_sdk.Ref_Box) *boxIndexRecord {
	return &boxIndexRecord{
		Id:       ref.ResourceId,
		Name:     ref.Name,
		Version:  ref.Version,
		Provider: ref.Provider,
	}
}

func (s *State) boxId(b *vagrant_server.Box) []byte {
	return []byte(b.Id)
}

func (s *State) boxIdByRef(b *vagrant_plugin_sdk.Ref_Box) []byte {
	return []byte(b.ResourceId)
}
