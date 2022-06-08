package state

import (
	"strconv"
	"strings"

	"google.golang.org/protobuf/proto"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

var (
	// sysBucket stores system-related information.
	sysBucket = []byte("system")

	// sysVersionKey stores the version of the data that is stored.
	// This is used for data migration.
	sysVersionKey = []byte("version")
)

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//
// DB Version
//
// THIS SHOULD BE CHANGED WITH EXTREME CAUTION. Changing this will force users
// to perform a db upgrade when they upgrade their Vagrant version.
//
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
const (
	dbVersion int64 = 1
)

func init() {
	dbBuckets = append(dbBuckets, sysBucket)
}

// dbInit sets up the database. This should be called once on all new
// DB handles before accepting API calls. It is safe to be called multiple
// times.
func dbInit(db *bolt.DB) error {
	return db.Update(func(tx *bolt.Tx) error {
		// Create all our buckets
		for _, b := range dbBuckets {
			if _, err := tx.CreateBucketIfNotExists(b); err != nil {
				return err
			}
		}

		// Check our data version
		sys := tx.Bucket(sysBucket)
		vsnRaw := sys.Get(sysVersionKey)

		// Initialize the version with our current version if it isn't set.
		if len(vsnRaw) == 0 {
			if err := sys.Put(sysVersionKey, []byte(strconv.FormatInt(dbVersion, 10))); err != nil {
				return status.Errorf(codes.Internal,
					"failed to write initial database version: %s", err)
			}
		} else {
			vsn, err := strconv.ParseInt(string(vsnRaw), 10, 64)
			if err != nil {
				return status.Errorf(codes.Internal,
					"failed to read database version: %s", err)
			}

			if vsn != dbVersion {
				return status.Errorf(codes.FailedPrecondition, strings.TrimSpace(`
The database version on disk does not match the server version.

The server cannot safely read this data. Please upgrade or downgrade your server
to a version that is capable of reading this data version. You can find this
information on the Vagrant website.

On-disk data version: %d
 Server data version: %d

`), vsn, dbVersion)
			}
		}

		return nil
	})
}

// dbPut is a helper to insert a proto.Message into a bucket for the given id.
// Any errors are automatically wrapped into a gRPC status error so they can
// be sent directly back.
func dbPut(b *bolt.Bucket, id []byte, msg proto.Message) error {
	enc, err := proto.Marshal(msg)
	if err != nil {
		return status.Errorf(codes.Internal, "failed to encode data: %s", err)
	}

	if err := b.Put(id, enc); err != nil {
		return status.Errorf(codes.Aborted, "failed to write data: %s", err)
	}

	return nil
}

// dbGet is a helper to get a single proto.Message from a bucket. Errors
// are guaranteed to be in gRPC status format.
func dbGet(b *bolt.Bucket, id []byte, msg proto.Message) error {
	raw := b.Get(id)
	if raw == nil {
		return status.Errorf(codes.NotFound, "record not found for ID: %s", id)
	}

	if err := proto.Unmarshal(raw, msg); err != nil {
		return status.Errorf(codes.Internal, "failed to decode data: %s", err)
	}

	return nil
}

// dbUpsert is a helper to upsert a message. The update boolean will cause
// this to error if the ID is not found. This reflects our API behavior for
// upserts so that we don't let the end user pick any ID.
func dbUpsert(b *bolt.Bucket, update bool, id []byte, msg proto.Message) error {
	// If we're updating, the ID must exist
	if update && b.Get([]byte(id)) == nil {
		return status.Errorf(codes.NotFound, "record not found for ID: %s", id)
	}

	// Insert
	return dbPut(b, id, msg)
}

func dbCount(b *bolt.DB, tableName string) int {
	count := 0
	b.View(func(tx *bolt.Tx) error {
		bucket := tx.Bucket([]byte(tableName))
		bucket.ForEach(func(k, v []byte) error {
			count++
			return nil
		})
		return nil
	})
	return count
}
