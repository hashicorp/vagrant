// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package state

import (
	"io/ioutil"
	"os"
	"path/filepath"
	"time"

	"github.com/glebarez/sqlite"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
	"google.golang.org/protobuf/proto"
	"gorm.io/gorm"
	"gorm.io/gorm/logger"
)

// TestState returns an initialized State for testing.
func TestState(t testing.T) *State {
	t.Helper()

	var result *State
	t.Cleanup(func() {
		t.Log("test state cleanup for", t.Name())
		result.Close()
	})

	result, err := New(
		hclog.New(&hclog.LoggerOptions{
			Name:            "testing",
			Level:           hclog.Trace,
			Output:          os.Stdout,
			IncludeLocation: true,
		}),
		TestDB(t),
	)
	require.NoError(t, err)
	return result
}

// TestStateReinit reinitializes the state by pretending to restart
// the server with the database associated with this state. This can be
// used to test index init logic.
//
// NOTE: The new state is created before the old one is closed so the
// shared in memory database is reused (data retained)
func TestStateReinit(t testing.T, s *State) *State {
	newState := TestState(t)
	require.NoError(t, s.Close())
	return newState
}

func TestDB(t testing.T) *gorm.DB {
	t.Helper()

	db, err := gorm.Open(sqlite.Open("file::memory:?cache=shared"),
		&gorm.Config{
			Logger: logger.New(
				hclog.New(&hclog.LoggerOptions{
					Name:            "testing",
					Level:           hclog.Warn,
					Output:          os.Stdout,
					IncludeLocation: false,
				}).StandardLogger(
					&hclog.StandardLoggerOptions{
						InferLevels: true,
					}),
				logger.Config{
					SlowThreshold:             200 * time.Millisecond,
					LogLevel:                  logger.Warn,
					IgnoreRecordNotFoundError: false,
					Colorful:                  true,
				},
			),
		})
	db.Exec("PRAGMA foreign_keys = ON")
	if err != nil {
		panic("failed to enable foreign key constraints: " + err.Error())
	}

	if err := db.AutoMigrate(models...); err != nil {
		require.NoError(t, err)
	}

	t.Cleanup(func() {
		dbconn, err := db.DB()
		if err == nil {
			dbconn.Close()
		}
	})

	return db
}

func RequireAndDB(t testing.T) (*require.Assertions, *gorm.DB) {
	db := TestDB(t)
	require := require.New(t)
	return require, db
}

func TestBasis(t testing.T, db *gorm.DB) *Basis {
	t.Helper()

	td := TestTempDir(t)
	b := &Basis{
		Name: filepath.Base(td),
		Path: td,
	}
	result := db.Save(b)
	require.NoError(t, result.Error)

	return b
}

// TestBasis creates the basis in the DB.
func TestBasisProto(t testing.T, s *State) *vagrant_plugin_sdk.Ref_Basis {
	t.Helper()

	return TestBasis(t, s.db).ToProtoRef()
}

func TestProject(t testing.T, db *gorm.DB) *Project {
	b := TestBasis(t, db)

	td := TestTempDir(t)
	p := &Project{
		Name:  filepath.Base(td),
		Path:  td,
		Basis: b,
	}
	result := db.Save(p)
	require.NoError(t, result.Error)

	return p
}

func TestProjectProto(t testing.T, s *State) *vagrant_plugin_sdk.Ref_Project {
	t.Helper()

	return TestProject(t, s.db).ToProtoRef()
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

func TestJobProto(t testing.T, src *vagrant_server.Job) *vagrant_server.Job {
	t.Helper()

	dst := &vagrant_server.Job{
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
	}

	proto.Merge(dst, src)

	return dst
}

func TestTempDir(t testing.T) string {
	t.Helper()

	dir, err := ioutil.TempDir("", "vagrant-test")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(dir) })
	return dir
}
