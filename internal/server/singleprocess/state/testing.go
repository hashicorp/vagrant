package state

import (
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
	bolt "go.etcd.io/bbolt"
)

// TestState returns an initialized State for testing.
func TestState(t testing.T) *State {
	result, err := New(hclog.L(), testDB(t))
	require.NoError(t, err)
	return result
}

// TestStateReinit reinitializes the state by pretending to restart
// the server with the database associated with this state. This can be
// used to test index init logic.
//
// This safely copies the entire DB so the old state can continue running
// with zero impact.
func TestStateReinit(t testing.T, s *State) *State {
	// Copy the old database to a brand new path
	td, err := ioutil.TempDir("", "test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })
	path := filepath.Join(td, "test.db")

	// Start db copy
	require.NoError(t, s.db.View(func(tx *bolt.Tx) error {
		return tx.CopyFile(path, 0600)
	}))

	// Open the new DB
	db, err := bolt.Open(path, 0600, nil)
	require.NoError(t, err)
	t.Cleanup(func() { db.Close() })

	// Init new state
	result, err := New(hclog.L(), db)
	require.NoError(t, err)
	return result
}

// TestStateRestart closes the given state and restarts it against the
// same DB file. Unlike TestStateReinit, this does not copy the data and
// the old state is no longer usable.
func TestStateRestart(t testing.T, s *State) (*State, error) {
	path := s.db.Path()
	require.NoError(t, s.Close())

	// Open the new DB
	db, err := bolt.Open(path, 0600, nil)
	require.NoError(t, err)
	t.Cleanup(func() { db.Close() })

	// Init new state
	return New(hclog.L(), db)
}

func testDB(t testing.T) *bolt.DB {
	t.Helper()

	// Temporary directory for the database
	td, err := ioutil.TempDir("", "test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	// Create the DB
	db, err := bolt.Open(filepath.Join(td, "test.db"), 0600, nil)
	require.NoError(t, err)
	t.Cleanup(func() { db.Close() })

	return db
}

// TestBasis creates the basis in the DB.
func testBasis(t testing.T, s *State) *vagrant_plugin_sdk.Ref_Basis {
	td := testTempDir(t)
	s.BasisPut(serverptypes.TestBasis(t, &vagrant_server.Basis{
		ResourceId: "test-basis",
		Path:       td,
		Name:       "test-basis",
	}))
	return &vagrant_plugin_sdk.Ref_Basis{
		ResourceId: "test-basis",
		Path:       td,
		Name:       "test-basis",
	}
}

func testProject(t testing.T, s *State) *vagrant_plugin_sdk.Ref_Project {
	basisRef := testBasis(t, s)
	s.ProjectPut(serverptypes.TestProject(t, &vagrant_server.Project{
		ResourceId: "test-project",
		Basis:      basisRef,
		Path:       "idontexist",
		Name:       "test-project",
	}))
	return &vagrant_plugin_sdk.Ref_Project{
		ResourceId: "test-project",
		Path:       "idontexist",
		Name:       "test-project",
		Basis:      basisRef,
	}
}

func testTempDir(t testing.T) string {
	dir, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}
