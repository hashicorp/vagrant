package state

import (
	"crypto/rand"
	"io"
	"sync/atomic"

	"google.golang.org/protobuf/proto"
	"github.com/hashicorp/go-memdb"
	bolt "go.etcd.io/bbolt"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var hmacKeyBucket = []byte("hmac_keys")

func init() {
	dbBuckets = append(dbBuckets, hmacKeyBucket)
	dbIndexers = append(dbIndexers, (*State).hmacKeyIndexInit)
	schemas = append(schemas, hmacKeyIndexSchema)
}

// HMACKeyEmpty returns true if no HMAC keys have been created. This will
// be true only when the server is in a bootstrap state.
func (s *State) HMACKeyEmpty() bool {
	return atomic.LoadUint32(&s.hmacKeyNotEmpty) == 0
}

// HMACKeyCreateIfNotExist creates a new HMAC key with the given ID and size. If a
// key with the given ID exists already it will be returned.
func (s *State) HMACKeyCreateIfNotExist(id string, size int) (*vagrant_server.HMACKey, error) {
	memTxn := s.inmem.Txn(true)
	defer memTxn.Abort()

	var result *vagrant_server.HMACKey
	err := s.db.Update(func(dbTxn *bolt.Tx) error {
		var err error

		// If we have this key already, then return that.
		result, err = s.hmacKeyGet(dbTxn, memTxn, id)
		if err != nil {
			return err
		}
		if result != nil {
			return nil
		}

		// We don't have the key, create it
		result, err = s.hmacKeyCreate(dbTxn, memTxn, id, size)
		return err
	})
	if err == nil {
		memTxn.Commit()
	}

	return result, err
}

func (s *State) hmacKeyCreate(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	id string,
	size int,
) (*vagrant_server.HMACKey, error) {
	// Get the global bucket and write the value to it.
	b := dbTxn.Bucket(hmacKeyBucket)
	raw := make([]byte, size)
	_, err := io.ReadFull(rand.Reader, raw)
	if err != nil {
		return nil, err
	}

	var key vagrant_server.HMACKey
	key.Id = id
	key.Key = raw

	// Persist our data
	if err := dbPut(b, []byte(id), &key); err != nil {
		return nil, err
	}

	// Create our index value and write that.
	return &key, s.hmacKeyIndexSet(memTxn, &key)
}

// HMACKeyGet gets an HMAC key by ID. This will return a nil value if it
// doesn't exist.
func (s *State) HMACKeyGet(id string) (*vagrant_server.HMACKey, error) {
	memTxn := s.inmem.Txn(false)
	defer memTxn.Abort()
	return s.hmacKeyGet(nil, memTxn, id)
}

func (s *State) hmacKeyGet(
	dbTxn *bolt.Tx,
	memTxn *memdb.Txn,
	id string,
) (*vagrant_server.HMACKey, error) {
	// Look for it in the index
	raw, err := memTxn.First(hmacKeyIndexTableName, hmacKeyIndexIdIndexName, id)
	if err != nil {
		return nil, err
	}
	if raw == nil {
		return nil, nil
	}

	// Read the value
	idx := raw.(*hmacKeyIndexRecord)
	return idx.Key, nil
}

// hmacKeyIndexSet writes an index record for a single HMAC key.
func (s *State) hmacKeyIndexSet(txn *memdb.Txn, value *vagrant_server.HMACKey) error {
	record := &hmacKeyIndexRecord{
		Id:  value.Id,
		Key: value,
	}

	// Insert the index
	if err := txn.Insert(hmacKeyIndexTableName, record); err != nil {
		return err
	}

	// Set that we're not empty
	atomic.StoreUint32(&s.hmacKeyNotEmpty, 1)

	return nil
}

// hmacKeyIndexInit initializes the hmacKey index from persisted data.
func (s *State) hmacKeyIndexInit(dbTxn *bolt.Tx, memTxn *memdb.Txn) error {
	// Reset that we're empty. In practice this doesn't happen but
	// for tests we might load the state store multiple times in-process.
	atomic.StoreUint32(&s.hmacKeyNotEmpty, 0)

	bucket := dbTxn.Bucket(hmacKeyBucket)
	return bucket.ForEach(func(k, v []byte) error {
		var value vagrant_server.HMACKey
		if err := proto.Unmarshal(v, &value); err != nil {
			return err
		}
		if err := s.hmacKeyIndexSet(memTxn, &value); err != nil {
			return err
		}

		return nil
	})
}

func hmacKeyIndexSchema() *memdb.TableSchema {
	return &memdb.TableSchema{
		Name: hmacKeyIndexTableName,
		Indexes: map[string]*memdb.IndexSchema{
			hmacKeyIndexIdIndexName: {
				Name:         hmacKeyIndexIdIndexName,
				AllowMissing: false,
				Unique:       true,
				Indexer: &memdb.StringFieldIndex{
					Field:     "Id",
					Lowercase: true,
				},
			},
		},
	}
}

const (
	hmacKeyIndexTableName   = "auth-key-index"
	hmacKeyIndexIdIndexName = "id"
)

type hmacKeyIndexRecord struct {
	Id  string
	Key *vagrant_server.HMACKey
}
