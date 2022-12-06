package state

import (
	"bufio"
	"compress/gzip"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"hash"
	"io"
	"os"
	"path/filepath"
	"strings"
	"time"

	"github.com/gofrs/flock"
	"github.com/hashicorp/go-hclog"
	"github.com/natefinch/atomic"
	bolt "go.etcd.io/bbolt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/pkg/protowriter"
	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// CreateSnapshot creates a database snapshot and writes it to the given writer.
//
// This will NOT buffer data to w, so you should wrap w in a bufio.Writer
// if you want buffering.
func (s *State) CreateSnapshot(w io.Writer) error {
	// We build up the checksum using a multiwriter from the protowriter.
	// This lets us figure out the checksum after the proto bytes are marshalled
	// but before gzip.
	checksum := sha256.New()

	gzw := gzip.NewWriter(w)
	defer gzw.Close()
	dw := protowriter.NewDelimitedWriter(io.MultiWriter(gzw, checksum))
	defer dw.Close()

	// Write our header
	if err := dw.WriteMsg(&vagrant_server.Snapshot_Header{
		Version: protocolversion.Current(),
		Format:  vagrant_server.Snapshot_Header_BOLT,
	}); err != nil {
		return err
	}

	return s.db.View(func(dbTxn *bolt.Tx) error {
		if err := dbTxn.ForEach(func(name []byte, b *bolt.Bucket) error {
			const chunkLenMax = 1024 * 1024 // 1 MB
			chunkLen := 0
			chunkItems := map[string][]byte{}

			// flushChunk is a function to flush the current chunk of data
			flushChunk := func() error {
				if err := dw.WriteMsg(&vagrant_server.Snapshot_BoltChunk{
					Bucket: string(name),
					Items:  chunkItems,
				}); err != nil {
					return err
				}

				chunkItems = map[string][]byte{}
				chunkLen = 0
				return nil
			}

			// Iterate and write the data
			if err := b.ForEach(func(k, v []byte) error {
				if len(v)+chunkLen > chunkLenMax {
					if err := flushChunk(); err != nil {
						return err
					}
				}

				chunkLen += len(v)
				chunkItems[string(k)] = v
				return nil
			}); err != nil {
				return err
			}

			// Write any final values
			return flushChunk()
		}); err != nil {
			return err
		}

		// Write our footer chunk
		if err := dw.WriteMsg(&vagrant_server.Snapshot_BoltChunk{Final: true}); err != nil {
			return err
		}

		// Write our trailer
		if err := dw.WriteMsg(&vagrant_server.Snapshot_Trailer{
			Checksum: &vagrant_server.Snapshot_Trailer_Sha256{
				Sha256: hex.EncodeToString(checksum.Sum(nil)),
			},
		}); err != nil {
			return err
		}

		return nil
	})
}

// StageRestoreSnapshot stages a database restore for the next server restart.
// This will create a temporary file alongside the data file so we must have
// write access to the directory containing the database.
func (s *State) StageRestoreSnapshot(r io.Reader) error {
	log := s.log.Named("restore")
	log.Warn("beginning to stage snapshot restore")

	ri := newRestoreInfo(log, s.db)
	if err := ri.Lock(); err != nil {
		return err
	}
	defer ri.Unlock()

	// Get our file info
	fi, err := os.Stat(s.db.Path())
	if err != nil {
		return err
	}

	// Open our temporary file and copy the restore contents into it.
	log.Info("copying the snapshot data to a temporary path", "path", ri.StageTempPath)
	tempF, err := os.OpenFile(ri.StageTempPath, os.O_RDWR|os.O_CREATE|os.O_TRUNC, fi.Mode())
	if err != nil {
		log.Error("error creating temporary path", "err", err)
		return err
	}
	n, err := io.Copy(tempF, r)
	log.Info("copied snapshot data", "len", n)
	tempF.Close()
	if err != nil {
		log.Error("error copying snapshot data", "err", err)
		return err
	}

	// We do want to check that this appears valid because if we can't open
	// the file then the server will never start again until it is cleaned up.
	log.Info("validating restore file")
	sr, closer, err := snapshotReader(ri.StageTempPath, nil)
	if err != nil {
		log.Error("error while validating restore file", "err", err)
		return fmt.Errorf("error validating restore data: %s", err)
	}

	var header vagrant_server.Snapshot_Header
	err = sr.ReadMsg(&header)
	if cerr := closer(); cerr != nil {
		err = cerr
	}
	if err != nil {
		log.Error("error while validating restore file", "err", err)
		return fmt.Errorf("error validating restore data: %s", err)
	}

	// Replace our file
	log.Info("atomically replacing file", "src", ri.StageTempPath, "dest", ri.StagePath)
	if err := atomic.ReplaceFile(ri.StageTempPath, ri.StagePath); err != nil {
		log.Error("error replacing file", "err", err)
		return err
	}

	// Open the new database
	log.Warn("snapshot staged for restore on next startup")
	return nil
}

// finalizeRestore checks for any staged restore and moves it into place.
// This will error if it fails for any reason which may prevent startup
// but we have to prevent startup because the user wanted a restore.
func finalizeRestore(log hclog.Logger, db *bolt.DB) (*bolt.DB, error) {
	log.Debug("checking if DB restore is requested")
	ri := newRestoreInfo(log, db)
	if err := ri.Lock(); err != nil {
		return db, err
	}
	defer ri.Unlock()

	_, err := os.Stat(ri.StagePath)
	if os.IsNotExist(err) {
		log.Debug("no restore file found, no DB restore requested")
		return db, nil
	}
	if err != nil {
		log.Error("error checking for restore file", "err", err)
		return db, err
	}

	log.Warn("restore file found, will initiate database restore", "path", ri.StagePath)

	// The file on disk should be in the form of vagrant_server.Snapshot. So what we need
	// to do next is parse out the header to determine the format, and then
	// based on the format, write the correct data to disk.
	log.Info("inspecting restore file to determine header")
	checksum := sha256.New()
	sr, closer, err := snapshotReader(ri.StagePath, checksum)
	if err != nil {
		log.Error("error while opening restore file", "err", err)
		return db, err
	}
	defer closer()

	// Get our header first, guaranteed first message
	var header vagrant_server.Snapshot_Header
	if err := sr.ReadMsg(&header); err != nil {
		log.Error("error while parsing restore header", "err", err)
		return db, fmt.Errorf("error reading restore header data: %s", err)
	}
	log.Info("snapshot header info",
		"created_by", header.Version.Version,
		"format", header.Format.String(),
	)

	// We currently only support bolt
	if header.Format != vagrant_server.Snapshot_Header_BOLT {
		return db, fmt.Errorf("invalid snapshot format (got code: %d)", header.Format)
	}

	// Open a temporary file to write our raw bolt data
	log.Info("reading bolt information and writing it into a new bolt db", "path", ri.StageTempPath)
	tempDb, err := bolt.Open(ri.StageTempPath, 0600, &bolt.Options{Timeout: 2 * time.Second})
	if err != nil {
		return db, err
	}
	for {
		var chunk vagrant_server.Snapshot_BoltChunk
		err := sr.ReadMsg(&chunk)
		if err == io.EOF {
			break
		}
		if err != nil {
			tempDb.Close()
			return db, err
		}

		if len(chunk.Bucket) > 0 && len(chunk.Items) > 0 {
			if err := tempDb.Update(func(dbTxn *bolt.Tx) error {
				b, err := dbTxn.CreateBucketIfNotExists([]byte(chunk.Bucket))
				if err != nil {
					return err
				}
				for k, v := range chunk.Items {
					if err := b.Put([]byte(k), v); err != nil {
						return err
					}
				}

				return nil
			}); err != nil {
				tempDb.Close()
				return db, err
			}
		}

		if chunk.Final {
			tempDb.Close()
			break
		}
	}

	// Determine our checksum. It is very important to do this here before
	// we read the trailer because the checksum is up to but not including
	// the trailer.
	finalChecksum := hex.EncodeToString(checksum.Sum(nil))

	// Read the trailer
	var trailer vagrant_server.Snapshot_Trailer
	if err := sr.ReadMsg(&trailer); err != nil {
		log.Error("error while parsing restore trailer", "err", err)
		return db, fmt.Errorf("error reading restore trailer data: %s", err)
	}

	// Validate the checksum
	switch v := trailer.Checksum.(type) {
	case *vagrant_server.Snapshot_Trailer_Sha256:
		if strings.ToLower(finalChecksum) != strings.ToLower(v.Sha256) {
			log.Error("checksum mismatch",
				"expected", v.Sha256,
				"actual", finalChecksum,
			)
			return db, fmt.Errorf("checksum mismatch, expected %s got %s", v.Sha256, finalChecksum)
		}

	default:
		log.Error("unknown checksum type", "type", fmt.Sprintf("%T", trailer.Checksum))
		return db, fmt.Errorf("error reading restore trailer data: unknown checksum type")
	}

	// Close our DB, we will reopen with the new one
	if err := db.Close(); err != nil {
		log.Error("failed to close db for restore", "err", err)
		return db, err
	}

	// Get our file info
	var mode os.FileMode = 0666
	if fi, err := os.Stat(ri.DBPath); err == nil {
		mode = fi.Mode()
	} else if !os.IsNotExist(err) {
		return db, err
	}

	// Replace our file
	log.Info("atomically replacing db file", "src", ri.StagePath, "dest", ri.DBPath)
	if err := atomic.ReplaceFile(ri.StageTempPath, ri.DBPath); err != nil {
		log.Error("error replacing file", "err", err)
		return db, err
	}

	// Delete our restore data
	log.Info("finished reading restore data, removing now")
	if err := os.Remove(ri.StagePath); err != nil {
		log.Error("error removing restore data", "err", err)
		return db, err
	}

	// Reopen the DB
	log.Info("reopening database", "path", ri.DBPath)
	db, err = bolt.Open(ri.DBPath, mode, &bolt.Options{
		Timeout: 2 * time.Second,
	})
	if err != nil {
		log.Error("error reopening db", "err", err)
		return db, err
	}

	log.Warn("database restore successful")
	return db, nil
}

// snapshotReader opens the delimited reader for a snapshot.
func snapshotReader(path string, h hash.Hash) (protowriter.Reader, func() error, error) {
	f, err := os.Open(path)
	if err != nil {
		return nil, nil, err
	}

	gzr, err := gzip.NewReader(f)
	if err != nil {
		f.Close()
		return nil, nil, err
	}

	if h == nil {
		h = sha256.New()
	}

	hbr := &hashedBufferedReader{
		R: bufio.NewReader(gzr),
		H: h,
	}

	const maxSize = 4096 * 1024 // 4MB
	dr := protowriter.NewDelimitedReader(hbr, maxSize)

	return dr, func() error {
		if err := dr.Close(); err != nil {
			return err
		}

		if err := gzr.Close(); err != nil {
			return err
		}

		return f.Close()
	}, nil
}

type restoreInfo struct {
	// DBPath is the final database path.
	DBPath string

	// StagePath is the final path where the staged restore data should
	// be placed. If this path exists, the data is expected to be valid
	// and not corrupted.
	StagePath string

	// StageTempPath is where the staged restore data should be temporarily
	// written to while it is still being loaded. This data if it exists
	// may be corrupted or incomplete until it is atomically moved to
	// StagePath.
	StageTempPath string

	fl  *flock.Flock
	log hclog.Logger
}

// newRestoreInfo gets the restore info from the given DB.
func newRestoreInfo(log hclog.Logger, db *bolt.DB) *restoreInfo {
	// Get our current directory
	destPath := db.Path()
	dir := filepath.Dir(destPath)

	// Paths to our restore file
	stagePath := filepath.Join(dir, "vagrant-restore.db")
	tempPath := stagePath + ".temp"
	lockPath := stagePath + ".lock"

	return &restoreInfo{
		DBPath:        destPath,
		StagePath:     stagePath,
		StageTempPath: tempPath,
		fl:            flock.New(lockPath),
		log:           log,
	}
}

// Lock locks the restore lockfile or returns an error if this failed.
// If the return value is nil, then Unlock must be called to unlock.
func (r *restoreInfo) Lock() error {
	// Create a file lock to ensure only one restore is happening at a time
	r.log.Trace("acquiring file lock for restore", "path", r.fl.String())
	locked, err := r.fl.TryLock()
	if err != nil {
		r.log.Error("error acquiring file lock", "err", err)
		return err
	}
	if !locked {
		r.log.Error("error acquiring file lock, lock already held")
		return status.Errorf(codes.Aborted,
			"failed to acquire file lock for restore, another restore may already be active")
	}

	return nil
}

// Unlock unlocks the file lock. This is only safe to call if a lock
// was successfully acquired.
func (r *restoreInfo) Unlock() error {
	r.log.Trace("releasing file lock for restore", "path", r.fl.String())
	return r.fl.Unlock()
}

// hashedBufferReader implements io.Reader and io.ByteReader for use
// with protowriter.Reader, and allows a checksum to be calculated
// as part of the read process.
type hashedBufferedReader struct {
	R *bufio.Reader
	H hash.Hash
}

func (r *hashedBufferedReader) ReadByte() (b byte, err error) {
	b, err = r.R.ReadByte()
	r.H.Write([]byte{b})
	return
}

func (r *hashedBufferedReader) Read(p []byte) (n int, err error) {
	n, err = r.R.Read(p)
	if n > 0 {
		r.H.Write(p[:n])
	}

	return
}
