// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package state

import (
	"sync"
	"testing"

	"github.com/hashicorp/go-memdb"
	"github.com/stretchr/testify/require"
)

type pti struct {
	Id string
}

func TestPruneOld(t *testing.T) {
	schema := &memdb.DBSchema{
		Tables: map[string]*memdb.TableSchema{
			"items": {
				Name: "items",
				Indexes: map[string]*memdb.IndexSchema{
					jobIdIndexName: {
						Name:         "id",
						AllowMissing: false,
						Unique:       true,
						Indexer: &memdb.StringFieldIndex{
							Field: "Id",
						},
					},
				},
			},
		},
	}

	t.Run("prunes none when there is enough room", func(t *testing.T) {
		require := require.New(t)

		inmem, err := memdb.NewMemDB(schema)
		require.NoError(err)

		txn := inmem.Txn(true)
		defer txn.Abort()

		require.NoError(txn.Insert("items", &pti{"B"}))
		require.NoError(txn.Insert("items", &pti{"C"}))
		require.NoError(txn.Insert("items", &pti{"A"}))
		require.NoError(txn.Insert("items", &pti{"D"}))

		// Weird order on purpose to validate lexical ordering on pruning.

		txn.Commit()

		txn = inmem.Txn(true)
		defer txn.Abort()

		var (
			mu      sync.Mutex
			indexed int = 4
		)

		cnt, err := pruneOld(txn, pruneOp{
			lock:      &mu,
			table:     "items",
			index:     "id",
			indexArgs: []interface{}{""},
			cur:       &indexed,
			max:       4,
		})
		require.NoError(err)

		txn.Commit()

		require.Equal(0, cnt)
		require.Equal(4, indexed)

		txn = inmem.Txn(false)
		defer txn.Abort()

		val, err := txn.First("items", "id", "A")
		require.NoError(err)
		require.NotNil(val)

		val, err = txn.First("items", "id", "B")
		require.NoError(err)
		require.NotNil(val)

		val, err = txn.First("items", "id", "C")
		require.NoError(err)
		require.NotNil(val)

		val, err = txn.First("items", "id", "D")
		require.NoError(err)
		require.NotNil(val)
	})

	t.Run("deletes a subset of records", func(t *testing.T) {
		require := require.New(t)

		inmem, err := memdb.NewMemDB(schema)
		require.NoError(err)

		txn := inmem.Txn(true)
		defer txn.Abort()

		require.NoError(txn.Insert("items", &pti{"B"}))
		require.NoError(txn.Insert("items", &pti{"C"}))
		require.NoError(txn.Insert("items", &pti{"A"}))
		require.NoError(txn.Insert("items", &pti{"D"}))

		// Weird order on purpose to validate lexical ordering on pruning.

		txn.Commit()

		txn = inmem.Txn(true)
		defer txn.Abort()

		var (
			mu      sync.Mutex
			indexed int = 4
		)

		cnt, err := pruneOld(txn, pruneOp{
			lock:      &mu,
			table:     "items",
			index:     "id",
			indexArgs: []interface{}{""},
			cur:       &indexed,
			max:       2,
		})
		require.NoError(err)

		txn.Commit()

		require.Equal(2, cnt)
		require.Equal(2, indexed)

		txn = inmem.Txn(false)
		defer txn.Abort()

		val, err := txn.First("items", "id", "A")
		require.NoError(err)
		require.Nil(val)

		val, err = txn.First("items", "id", "B")
		require.NoError(err)
		require.Nil(val)

		val, err = txn.First("items", "id", "C")
		require.NoError(err)
		require.NotNil(val)

		val, err = txn.First("items", "id", "D")
		require.NoError(err)
		require.NotNil(val)
	})

	t.Run("deletes all records", func(t *testing.T) {
		require := require.New(t)

		inmem, err := memdb.NewMemDB(schema)
		require.NoError(err)

		txn := inmem.Txn(true)
		defer txn.Abort()

		require.NoError(txn.Insert("items", &pti{"B"}))
		require.NoError(txn.Insert("items", &pti{"C"}))
		require.NoError(txn.Insert("items", &pti{"A"}))
		require.NoError(txn.Insert("items", &pti{"D"}))

		// Weird order on purpose to validate lexical ordering on pruning.

		txn.Commit()

		txn = inmem.Txn(true)
		defer txn.Abort()

		var (
			mu      sync.Mutex
			indexed int = 4
		)

		cnt, err := pruneOld(txn, pruneOp{
			lock:      &mu,
			table:     "items",
			index:     "id",
			indexArgs: []interface{}{""},
			cur:       &indexed,
			max:       0,
		})
		require.NoError(err)

		txn.Commit()

		require.Equal(4, cnt)
		require.Equal(0, indexed)

		txn = inmem.Txn(false)
		defer txn.Abort()

		val, err := txn.First("items", "id", "A")
		require.NoError(err)
		require.Nil(val)

		val, err = txn.First("items", "id", "B")
		require.NoError(err)
		require.Nil(val)

		val, err = txn.First("items", "id", "C")
		require.NoError(err)
		require.Nil(val)

		val, err = txn.First("items", "id", "D")
		require.NoError(err)
		require.Nil(val)
	})

}
