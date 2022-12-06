package state

import (
	bolt "go.etcd.io/bbolt"
)

var (
	serverIdKey = []byte("id")
)

// ServerIdSet writes the server ID.
func (s *State) ServerIdSet(id string) error {
	return s.db.Update(func(dbTxn *bolt.Tx) error {
		return dbTxn.Bucket(serverConfigBucket).Put(serverIdKey, []byte(id))
	})
}

// ServerIdGet gets the server ID.
func (s *State) ServerIdGet() (string, error) {
	var result string
	err := s.db.View(func(dbTxn *bolt.Tx) error {
		result = string(dbTxn.Bucket(serverConfigBucket).Get(serverIdKey))
		return nil
	})

	return result, err
}
