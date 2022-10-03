package state

import (
	"bytes"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/glebarez/sqlite"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// TestState returns an initialized State for testing.
func TestState(t testing.T) *State {
	t.Helper()

	var buf bytes.Buffer
	l := hclog.New(&hclog.LoggerOptions{
		Name:            "test",
		Level:           hclog.Trace,
		Output:          &buf,
		IncludeLocation: true,
	})

	t.Cleanup(func() {
		t.Log(buf.String())
	})
	result, err := New(l, testDB(t))
	require.NoError(t, err)
	return result
}

// // TestStateReinit reinitializes the state by pretending to restart
// // the server with the database associated with this state. This can be
// // used to test index init logic.
// //
// // This safely copies the entire DB so the old state can continue running
// // with zero impact.
// func TestStateReinit(t testing.T, s *State) *State {
// 	// Copy the old database to a brand new path
// 	td, err := ioutil.TempDir("", "test")
// 	require.NoError(t, err)
// 	t.Cleanup(func() { os.RemoveAll(td) })
// 	path := filepath.Join(td, "test.db")

// 	// Start db copy
// 	require.NoError(t, s.db.View(func(tx *bolt.Tx) error {
// 		return tx.CopyFile(path, 0600)
// 	}))

// 	// Open the new DB
// 	db, err := bolt.Open(path, 0600, nil)
// 	require.NoError(t, err)
// 	t.Cleanup(func() { db.Close() })

// 	// Init new state
// 	result, err := New(hclog.L(), db)
// 	require.NoError(t, err)
// 	return result
// }

// // TestStateRestart closes the given state and restarts it against the
// // same DB file. Unlike TestStateReinit, this does not copy the data and
// // the old state is no longer usable.
// func TestStateRestart(t testing.T, s *State) (*State, error) {
// 	path := s.db.Path()
// 	require.NoError(t, s.Close())

// 	// Open the new DB
// 	db, err := bolt.Open(path, 0600, nil)
// 	require.NoError(t, err)
// 	t.Cleanup(func() { db.Close() })

// 	// Init new state
// 	return New(hclog.L(), db)
// }

func testDB(t testing.T) *gorm.DB {
	t.Helper()

	db, err := gorm.Open(sqlite.Open(""), &gorm.Config{
		Logger: logger.Default.LogMode(logger.Silent),
	})
	db.Exec("PRAGMA foreign_keys = ON")
	if err != nil {
		panic("failed to enable foreign key constraints: " + err.Error())
	}

	require.NoError(t, err)
	t.Cleanup(func() {
		dbconn, err := db.DB()
		if err == nil {
			dbconn.Close()
		}
	})

	return db
}

func requireAndDB(t testing.T) (*require.Assertions, *gorm.DB) {
	db := testDB(t)
	require := require.New(t)
	if err := db.AutoMigrate(models...); err != nil {
		require.NoError(err)
	}
	return require, db
}

func testBasis(t testing.T, db *gorm.DB) *Basis {
	t.Helper()

	td := testTempDir(t)
	b := &Basis{
		Name: filepath.Base(td),
		Path: td,
	}
	result := db.Save(b)
	require.NoError(t, result.Error)

	return b
}

// TestBasis creates the basis in the DB.
func testBasisProto(t testing.T, s *State) *vagrant_plugin_sdk.Ref_Basis {
	t.Helper()

	return testBasis(t, s.db).ToProtoRef()
}

func testProject(t testing.T, db *gorm.DB) *Project {
	b := testBasis(t, db)

	td := testTempDir(t)
	p := &Project{
		Name:  filepath.Base(td),
		Path:  td,
		Basis: b,
	}
	result := db.Save(p)
	require.NoError(t, result.Error)

	return p
}

func testProjectProto(t testing.T, s *State) *vagrant_plugin_sdk.Ref_Project {
	t.Helper()

	return testProject(t, s.db).ToProtoRef()
}

func testRunnerProto(t testing.T, s *State, src *vagrant_server.Runner) *vagrant_server.Runner {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Runner{}
	}
	id, err := server.Id()
	require.NoError(t, err)
	base := &vagrant_server.Runner{Id: id}
	require.NoError(t, mergo.Merge(src, base))

	var runner Runner
	require.NoError(t, s.decode(src, &runner))
	result := s.db.Save(&runner)
	require.NoError(t, result.Error)

	return runner.ToProto()
}

func testJobProto(t testing.T, src *vagrant_server.Job) *vagrant_server.Job {
	t.Helper()

	require.NoError(t, mergo.Merge(src,
		&vagrant_server.Job{
			TargetRunner: &vagrant_server.Ref_Runner{
				Target: &vagrant_server.Ref_Runner_Any{
					Any: &vagrant_server.Ref_RunnerAny{},
				},
			},
			DataSource: &vagrant_server.Job_DataSource{
				Source: &vagrant_server.Job_DataSource_Local{
					Local: &vagrant_server.Job_Local{},
				},
			},
			Operation: &vagrant_server.Job_Noop_{
				Noop: &vagrant_server.Job_Noop{},
			},
		},
	))

	return src
}

func testTempDir(t testing.T) string {
	t.Helper()

	dir, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}
