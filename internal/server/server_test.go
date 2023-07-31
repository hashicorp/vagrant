// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

// TODO: mocks need to be regenerated for this

// import (
// 	"context"
// 	"strings"
// 	"testing"
// 	"time"

// 	"github.com/stretchr/testify/mock"
// 	"github.com/stretchr/testify/require"
// 	"google.golang.org/grpc/codes"
// 	"google.golang.org/grpc/status"

// 	"github.com/hashicorp/vagrant-plugin-sdk/component"
// 	pbmocks "github.com/hashicorp/vagrant/internal/server/gen/mocks"
// 	"github.com/hashicorp/vagrant/internal/server/gen/vagrant_server"
// )

// func TestComponentEnum(t *testing.T) {
// 	for idx, name := range vagrant_server.Component_Type_name {
// 		// skip the invalid value
// 		if idx == 0 {
// 			continue
// 		}

// 		typ := component.Type(idx)
// 		require.Equal(t, strings.ToUpper(typ.String()), strings.ToUpper(name))
// 	}
// }

// func TestRun_reconnect(t *testing.T) {
// 	require := require.New(t)
// 	ctx, cancel := context.WithCancel(context.Background())
// 	defer cancel()

// 	m := &pbmocks.VagrantServer{}
// 	m.On("GetVersionInfo", mock.Anything, mock.Anything).Return(testVersionInfoResponse(), nil)
// 	m.On("GetWorkspace", mock.Anything, mock.Anything).Return(&vagrant_server.GetWorkspaceResponse{}, nil)

// 	// Create the server
// 	restartCh := make(chan struct{})
// 	client := TestServer(t, m,
// 		TestWithContext(ctx),
// 		TestWithRestart(restartCh),
// 	)

// 	// Request should work
// 	_, err := client.GetWorkspace(ctx, &vagrant_server.GetWorkspaceRequest{
// 		Workspace: &vagrant_server.Ref_Workspace{
// 			Workspace: "test",
// 		},
// 	})
// 	require.NoError(err)

// 	// Stop it
// 	cancel()

// 	// Should not work
// 	require.Eventually(func() bool {
// 		_, err := client.GetWorkspace(context.Background(), &vagrant_server.GetWorkspaceRequest{
// 			Workspace: &vagrant_server.Ref_Workspace{
// 				Workspace: "test",
// 			},
// 		})
// 		t.Logf("error: %s", err)
// 		return status.Code(err) == codes.Unavailable
// 	}, 2*time.Second, 10*time.Millisecond)

// 	// Restart
// 	restartCh <- struct{}{}

// 	// Should work
// 	require.Eventually(func() bool {
// 		_, err := client.GetWorkspace(context.Background(), &vagrant_server.GetWorkspaceRequest{
// 			Workspace: &vagrant_server.Ref_Workspace{
// 				Workspace: "test",
// 			},
// 		})
// 		return err == nil
// 	}, 5*time.Second, 10*time.Millisecond)
// }
