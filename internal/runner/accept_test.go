// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package runner

// import (
// 	"context"
// 	"os"
// 	"os/exec"
// 	"path/filepath"
// 	"testing"
// 	"time"

// 	"github.com/stretchr/testify/require"

// 	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
// 	"github.com/hashicorp/vagrant/internal/core"
// 	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
// 	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
// 	"github.com/hashicorp/vagrant/internal/server/singleprocess"
// )

// var testHasGit bool

// func init() {
// 	if _, err := exec.LookPath("git"); err == nil {
// 		testHasGit = true
// 	}
// }

// func TestRunnerAccept(t *testing.T) {
// 	require := require.New(t)
// 	ctx := context.Background()

// 	// Setup our runner
// 	client := singleprocess.TestServer(t)
// 	runner := TestRunner(t, WithClient(client))
// 	defer runner.Close()
// 	require.NoError(runner.Start())

// 	// Initialize our basis
// 	testBasis := TestBasis(t, core.WithClient(client))

// 	// Queue a job
// 	queueResp, err := client.QueueJob(ctx, &vagrant_server.QueueJobRequest{
// 		Job: serverptypes.TestJobNew(t, &vagrant_server.Job{
// 			Target: &vagrant_plugin_sdk.Ref_Target{
// 				ResourceId: "TESTMACH",
// 				Project: &vagrant_plugin_sdk.Ref_Project{
// 					ResourceId: "TESTPROJ",
// 					Basis:      testBasis,
// 				},
// 			},
// 		}),
// 	})
// 	require.NoError(err)
// 	jobId := queueResp.JobId

// 	// Accept should complete
// 	require.NoError(runner.Accept(ctx))

// 	// Verify that the job is completed
// 	job, err := client.GetJob(ctx, &vagrant_server.GetJobRequest{JobId: jobId})
// 	require.NoError(err)
// 	require.Equal(vagrant_server.Job_SUCCESS, job.State)
// }

// func TestRunnerAccept_cancelContext(t *testing.T) {
// 	require := require.New(t)
// 	ctx, cancel := context.WithCancel(context.Background())

// 	// Setup our runner
// 	client := singleprocess.TestServer(t)
// 	runner := TestRunner(t, WithClient(client))
// 	defer runner.Close()
// 	require.NoError(runner.Start())

// 	// Initialize our basis
// 	testBasis := TestBasis(t, core.WithClient(client))

// 	// Set a blocker
// 	noopCh := make(chan struct{})
// 	runner.noopCh = noopCh

// 	// Queue a job
// 	queueResp, err := client.QueueJob(ctx, &vagrant_server.QueueJobRequest{
// 		Job: serverptypes.TestJobNew(t, &vagrant_server.Job{
// 			Target: &vagrant_plugin_sdk.Ref_Target{
// 				ResourceId: "TESTMACH",
// 				Project: &vagrant_plugin_sdk.Ref_Project{
// 					ResourceId: "TESTPROJ",
// 					Basis:      testBasis,
// 				},
// 			},
// 		}),
// 	})
// 	require.NoError(err)
// 	jobId := queueResp.JobId

// 	// Cancel the context eventually. This isn't CI-sensitive cause
// 	// we'll block no matter what.
// 	time.AfterFunc(500*time.Millisecond, cancel)

// 	// Accept should complete with an error
// 	require.NoError(runner.Accept(ctx))

// 	// Verify that the job is completed
// 	require.Eventually(func() bool {
// 		job, err := client.GetJob(context.Background(), &vagrant_server.GetJobRequest{JobId: jobId})
// 		require.NoError(err)
// 		return job.State == vagrant_server.Job_ERROR
// 	}, 3*time.Second, 25*time.Millisecond)
// }

// func TestRunnerAccept_cancelJob(t *testing.T) {
// 	require := require.New(t)
// 	ctx := context.Background()

// 	// Setup our runner
// 	client := singleprocess.TestServer(t)
// 	runner := TestRunner(t, WithClient(client))
// 	require.NoError(runner.Start())

// 	// Initialize our basis
// 	testBasis := TestBasis(t, core.WithClient(client))

// 	// Set a blocker
// 	noopCh := make(chan struct{})
// 	runner.noopCh = noopCh

// 	// Queue a job
// 	queueResp, err := client.QueueJob(ctx, &vagrant_server.QueueJobRequest{
// 		Job: serverptypes.TestJobNew(t, &vagrant_server.Job{
// 			Target: &vagrant_plugin_sdk.Ref_Target{
// 				ResourceId: "TESTMACH",
// 				Project: &vagrant_plugin_sdk.Ref_Project{
// 					ResourceId: "TESTPROJ",
// 					Basis:      testBasis,
// 				},
// 			},
// 		}),
// 	})
// 	require.NoError(err)
// 	jobId := queueResp.JobId

// 	// Cancel the context eventually. This isn't CI-sensitive cause
// 	// we'll block no matter what.
// 	time.AfterFunc(500*time.Millisecond, func() {
// 		_, err := client.CancelJob(ctx, &vagrant_server.CancelJobRequest{
// 			JobId: jobId,
// 		})
// 		require.NoError(err)
// 	})

// 	// Accept should complete with an error
// 	require.NoError(runner.Accept(ctx))

// 	// Verify that the job is completed
// 	require.Eventually(func() bool {
// 		job, err := client.GetJob(context.Background(), &vagrant_server.GetJobRequest{JobId: jobId})
// 		require.NoError(err)
// 		return job.State == vagrant_server.Job_ERROR
// 	}, 3*time.Second, 25*time.Millisecond)
// }

// func TestRunnerAccept_gitData(t *testing.T) {
// 	if !testHasGit {
// 		t.Skip("git not installed")
// 		return
// 	}

// 	require := require.New(t)
// 	ctx := context.Background()

// 	// Get a repo path
// 	path := testGitFixture(t, "git-noop")

// 	// Setup our runner
// 	client := singleprocess.TestServer(t)
// 	runner := TestRunner(t, WithClient(client))
// 	require.NoError(runner.Start())

// 	// Initialize our basis
// 	testBasis := TestBasis(t, core.WithClient(client))

// 	// Queue a job
// 	queueResp, err := client.QueueJob(ctx, &vagrant_server.QueueJobRequest{
// 		Job: serverptypes.TestJobNew(t, &vagrant_server.Job{
// 			DataSource: &vagrant_server.Job_DataSource{
// 				Source: &vagrant_server.Job_DataSource_Git{
// 					Git: &vagrant_server.Job_Git{
// 						Url: path,
// 					},
// 				},
// 			},
// 			Target: &vagrant_plugin_sdk.Ref_Target{
// 				ResourceId: "TESTMACH",
// 				Project: &vagrant_plugin_sdk.Ref_Project{
// 					ResourceId: "TESTPROJ",
// 					Basis:      testBasis,
// 				},
// 			},
// 		}),
// 	})

// 	require.NoError(err)
// 	jobId := queueResp.JobId

// 	// Accept should complete
// 	require.NoError(runner.Accept(ctx))

// 	// Verify that the job is completed
// 	job, err := client.GetJob(ctx, &vagrant_server.GetJobRequest{JobId: jobId})
// 	require.NoError(err)
// 	require.Equal(vagrant_server.Job_SUCCESS, job.State)
// }

// // testGitFixture MUST be called before TestRunner since TestRunner
// // changes our working directory.
// func testGitFixture(t *testing.T, n string) string {
// 	t.Helper()

// 	// We need to get our working directory since the TestRunner call
// 	// changes it.
// 	wd, err := os.Getwd()
// 	require.NoError(t, err)
// 	wd, err = filepath.Abs(wd)
// 	require.NoError(t, err)
// 	path := filepath.Join(wd, "testdata", n)

// 	// Look for a DOTgit
// 	original := filepath.Join(path, "DOTgit")
// 	_, err = os.Stat(original)
// 	require.NoError(t, err)

// 	// Rename it
// 	newPath := filepath.Join(path, ".git")
// 	require.NoError(t, os.Rename(original, newPath))
// 	t.Cleanup(func() { os.Rename(newPath, original) })

// 	return path
// }
