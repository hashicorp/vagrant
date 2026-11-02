// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestVersionUnaryInterceptor(t *testing.T) {
	f := versionUnaryInterceptor(&vagrant_server.VersionInfo{
		Api: &vagrant_server.VersionInfo_ProtocolVersion{
			Current: 10,
			Minimum: 2,
		},

		Entrypoint: &vagrant_server.VersionInfo_ProtocolVersion{
			Current: 10,
			Minimum: 5,
		},

		Version: "1.2.3",
	})

	t.Run("no headers", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs())

		// Call
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.vagrant.Vagrant/Foo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			return nil, nil
		})
		require.False(called)
		require.Error(err)
		require.Contains(err.Error(), "is not set")
	})

	t.Run("no headers on GetVersionInfo", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs())

		// Call
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.vagrant.Vagrant/GetVersionInfo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			return nil, nil
		})
		require.True(called)
		require.NoError(err)
	})

	t.Run("no headers on a different service", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs())

		// Call
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.notvagrant.Vagrant/Foo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			return nil, nil
		})
		require.True(called)
		require.NoError(err)
	})

	t.Run("valid API", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs(
			protocolversion.HeaderClientApiProtocol, "4,7",
		))

		// Call
		var actual context.Context
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.vagrant.Vagrant/Foo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			actual = ctx
			return nil, nil
		})
		require.True(called)
		require.NoError(err)

		// Check metadata
		require.Equal(uint32(7), protocolversion.FromContext(actual))
	})

	t.Run("invalid API", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs(
			protocolversion.HeaderClientApiProtocol, "11,14",
			protocolversion.HeaderClientEntrypointProtocol, "4,7",
		))

		// Call
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.vagrant.Vagrant/Foo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			return nil, nil
		})
		require.False(called)
		require.Error(err)
		require.Contains(err.Error(), "outdated")
	})

	t.Run("valid Entrypoint", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs(
			protocolversion.HeaderClientApiProtocol, "4,7",
			protocolversion.HeaderClientEntrypointProtocol, "4,6",
		))

		// Call
		var actual context.Context
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.vagrant.Vagrant/EntrypointFoo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			actual = ctx
			return nil, nil
		})
		require.True(called)
		require.NoError(err)

		// Check metadata
		require.Equal(uint32(6), protocolversion.FromContext(actual))
	})

	t.Run("invalid Entrypoint", func(t *testing.T) {
		require := require.New(t)

		ctx := metadata.NewIncomingContext(context.Background(), metadata.Pairs(
			protocolversion.HeaderClientApiProtocol, "4,7",
			protocolversion.HeaderClientEntrypointProtocol, "2,3",
		))

		// Call
		called := false
		_, err := f(ctx, nil, &grpc.UnaryServerInfo{
			FullMethod: "/hashicorp.vagrant.Vagrant/EntrypointFoo",
		}, func(
			ctx context.Context,
			req interface{},
		) (interface{}, error) {
			called = true
			return nil, nil
		})
		require.False(called)
		require.Error(err)
		require.Contains(err.Error(), "outdated")
	})
}
