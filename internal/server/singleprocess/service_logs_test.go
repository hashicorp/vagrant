// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

// import (
// 	"context"
// 	"strconv"
// 	"testing"
// 	"time"

// 	"github.com/stretchr/testify/require"

// 	"github.com/hashicorp/vagrant/internal/server"
// 	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
// 	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
// )

// func TestServiceGetLogStream(t *testing.T) {
// 	ctx := context.Background()

// 	// Create our server
// 	impl, err := New(WithDB(testDB(t)))
// 	require.NoError(t, err)
// 	client := server.TestServer(t, impl)

// 	// Register our instances
// 	resp, err := client.UpsertDeployment(ctx, &vagrant_server.UpsertDeploymentRequest{
// 		Deployment: serverptypes.TestValidDeployment(t, &vagrant_server.Deployment{
// 			Component: &vagrant_server.Component{
// 				Name: "testapp",
// 			},
// 		}),
// 	})

// 	require.NoError(t, err)

// 	dep := resp.Deployment
// 	configClient, err := client.EntrypointConfig(ctx, &vagrant_server.EntrypointConfigRequest{
// 		DeploymentId: dep.Id,
// 		InstanceId:   "1",
// 	})
// 	require.NoError(t, err)
// 	_, err = configClient.Recv()
// 	require.NoError(t, err)

// 	// Simplify writing tests
// 	type Req = vagrant_server.UpsertDeploymentRequest

// 	require := require.New(t)

// 	// Create the stream and send some log messages
// 	logSendClient, err := client.EntrypointLogStream(ctx)
// 	require.NoError(err)
// 	for i := 0; i < 5; i++ {
// 		var entries []*vagrant_server.LogBatch_Entry
// 		for j := 0; j < 5; j++ {
// 			entries = append(entries, &vagrant_server.LogBatch_Entry{
// 				Line: strconv.Itoa(5*i + j),
// 			})
// 		}

// 		logSendClient.Send(&vagrant_server.EntrypointLogBatch{
// 			InstanceId: "1",
// 			Lines:      entries,
// 		})
// 	}
// 	time.Sleep(100 * time.Millisecond)

// 	// Connect to the stream and download the logs
// 	logRecvClient, err := client.GetLogStream(ctx, &vagrant_server.GetLogStreamRequest{
// 		Scope: &vagrant_server.GetLogStreamRequest_DeploymentId{
// 			DeploymentId: dep.Id,
// 		},
// 	})
// 	require.NoError(err)

// 	// Get a batch
// 	batch, err := logRecvClient.Recv()
// 	require.NoError(err)
// 	require.NotEmpty(batch.Lines)
// 	require.Len(batch.Lines, 25)
// }

// func TestServiceGetLogStream_byApp(t *testing.T) {
// 	ctx := context.Background()

// 	// Create our server
// 	impl, err := New(WithDB(testDB(t)))
// 	require.NoError(t, err)
// 	client := server.TestServer(t, impl)

// 	// Setup our references
// 	refApp := &vagrant_server.Ref_Application{
// 		Project:     "test",
// 		Application: "app",
// 	}
// 	refWs := &vagrant_server.Ref_Workspace{
// 		Workspace: "ws",
// 	}

// 	// Register our instances
// 	resp, err := client.UpsertDeployment(ctx, &vagrant_server.UpsertDeploymentRequest{
// 		Deployment: serverptypes.TestValidDeployment(t, &vagrant_server.Deployment{
// 			Application: refApp,
// 			Workspace:   refWs,
// 			Component: &vagrant_server.Component{
// 				Name: "testapp",
// 			},
// 		}),
// 	})

// 	require.NoError(t, err)

// 	dep := resp.Deployment
// 	configClient, err := client.EntrypointConfig(ctx, &vagrant_server.EntrypointConfigRequest{
// 		DeploymentId: dep.Id,
// 		InstanceId:   "1",
// 	})
// 	require.NoError(t, err)
// 	_, err = configClient.Recv()
// 	require.NoError(t, err)

// 	// Simplify writing tests
// 	type Req = vagrant_server.UpsertDeploymentRequest

// 	require := require.New(t)

// 	// Create the stream and send some log messages
// 	logSendClient, err := client.EntrypointLogStream(ctx)
// 	require.NoError(err)
// 	for i := 0; i < 5; i++ {
// 		var entries []*vagrant_server.LogBatch_Entry
// 		for j := 0; j < 5; j++ {
// 			entries = append(entries, &vagrant_server.LogBatch_Entry{
// 				Line: strconv.Itoa(5*i + j),
// 			})
// 		}

// 		logSendClient.Send(&vagrant_server.EntrypointLogBatch{
// 			InstanceId: "1",
// 			Lines:      entries,
// 		})
// 	}
// 	time.Sleep(100 * time.Millisecond)

// 	// Connect to the stream and download the logs
// 	logRecvClient, err := client.GetLogStream(ctx, &vagrant_server.GetLogStreamRequest{
// 		Scope: &vagrant_server.GetLogStreamRequest_Application_{
// 			Application: &vagrant_server.GetLogStreamRequest_Application{
// 				Application: refApp,
// 				Workspace:   refWs,
// 			},
// 		},
// 	})
// 	require.NoError(err)

// 	// Get a batch
// 	batch, err := logRecvClient.Recv()
// 	require.NoError(err)
// 	require.NotEmpty(batch.Lines)
// 	require.Len(batch.Lines, 25)
// }
