// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"context"
	"net"

	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// TestServer starts a server and returns a gRPC client to that server.
// We use t.Cleanup to ensure resources are automatically cleaned up.
func TestServer(t testing.T, impl vagrant_server.VagrantServer, opts ...TestOption) *serverclient.VagrantClient {
	require := require.New(t)

	c := testConfig{
		ctx: context.Background(),
	}
	for _, opt := range opts {
		opt(&c)
	}

	// Listen on a random port
	ln, err := net.Listen("tcp", "127.0.0.1:")
	require.NoError(err)
	t.Cleanup(func() { ln.Close() })

	// We make run a function since we'll call it to restart too
	run := func(ctx context.Context) context.CancelFunc {
		ctx, cancel := context.WithCancel(ctx)
		go Run(
			WithContext(ctx),
			WithGRPC(ln),
			WithImpl(impl),
		)
		t.Cleanup(func() { cancel() })

		return cancel
	}

	// Create the server
	cancel := run(c.ctx)

	// If we have a restart channel, then listen to that for restarts.
	if c.restartCh != nil {
		doneCh := make(chan struct{})
		t.Cleanup(func() { close(doneCh) })

		go func() {
			for {
				select {
				case <-c.restartCh:
					// Cancel the old context
					cancel()

					// This can fail, but it probably won't. Can't think of
					// a cleaner way since gRPC force closes its listener.
					ln, err = net.Listen("tcp", ln.Addr().String())
					if err != nil {
						return
					}

					// Create a new one
					cancel = run(context.Background())

				case <-doneCh:
					return
				}
			}
		}()
	}

	// Get our version info we'll set on the client
	vsnInfo := testVersionInfoResponse().Info

	// Connect, this should retry in the case Run is not going yet
	conn, err := grpc.DialContext(context.Background(), ln.Addr().String(),
		grpc.WithBlock(),
		grpc.WithInsecure(),
		grpc.WithUnaryInterceptor(protocolversion.UnaryClientInterceptor(vsnInfo)),
		grpc.WithStreamInterceptor(protocolversion.StreamClientInterceptor(vsnInfo)),
	)
	require.NoError(err)
	t.Cleanup(func() { conn.Close() })

	return serverclient.WrapVagrantClient(conn)
}

// TestOption is used with TestServer to configure test behavior.
type TestOption func(*testConfig)

type testConfig struct {
	ctx       context.Context
	restartCh <-chan struct{}
}

// TestWithContext specifies a context to use with the test server. When
// this is done then the server will exit.
func TestWithContext(ctx context.Context) TestOption {
	return func(c *testConfig) {
		c.ctx = ctx
	}
}

// TestWithRestart specifies a channel that will be sent to to trigger
// a restart. The restart happens asynchronously. If you want to ensure the
// server is shutdown first, use TestWithContext, shut it down, wait for
// errors on the API, then restart.
func TestWithRestart(ch <-chan struct{}) TestOption {
	return func(c *testConfig) {
		c.restartCh = ch
	}
}

func testVersionInfoResponse() *vagrant_server.GetVersionInfoResponse {
	return &vagrant_server.GetVersionInfoResponse{
		Info: &vagrant_server.VersionInfo{
			Api: &vagrant_server.VersionInfo_ProtocolVersion{
				Current: 10,
				Minimum: 1,
			},

			Entrypoint: &vagrant_server.VersionInfo_ProtocolVersion{
				Current: 10,
				Minimum: 1,
			},
		},
	}
}
