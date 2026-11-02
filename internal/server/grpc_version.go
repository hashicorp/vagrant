// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"context"
	"strings"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// versionUnaryInterceptor returns a gRPC unary interceptor that negotiates
// the protocol version to use and sets it in the context using
// protocolversion.WithContext.
func versionUnaryInterceptor(serverInfo *vagrant_server.VersionInfo) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler) (interface{}, error) {
		typ, ok := versionType(info.FullMethod)
		if !ok {
			return handler(ctx, req)
		}

		ctx, err := versionContext(ctx, typ, serverInfo)
		if err != nil {
			return nil, err
		}

		return handler(ctx, req)
	}
}

// versionStreamInterceptor returns a gRPC unary interceptor that negotiates
// the protocol version to use and sets it in the context using
// protocolversion.WithContext.
func versionStreamInterceptor(serverInfo *vagrant_server.VersionInfo) grpc.StreamServerInterceptor {
	return func(
		srv interface{},
		ss grpc.ServerStream,
		info *grpc.StreamServerInfo,
		handler grpc.StreamHandler) error {
		typ, ok := versionType(info.FullMethod)
		if !ok {
			return handler(srv, ss)
		}

		ctx := ss.Context()
		ctx, err := versionContext(ctx, typ, serverInfo)
		if err != nil {
			return err
		}

		// Invoke the handler.
		return handler(srv, &versionStream{
			ServerStream: ss,
			context:      ctx,
		})
	}
}

// versionType returns the type of protocol version we should negotiate.
func versionType(fullMethod string) (protocolversion.Type, bool) {
	// Only care about vagrant APIs and ignore the version info call.
	if !strings.HasPrefix(fullMethod, "/hashicorp.vagrant.Vagrant/") {
		return protocolversion.Invalid, false
	}

	// Get the method
	idx := strings.LastIndex(fullMethod, "/")
	if idx == -1 {
		return protocolversion.Invalid, false
	}
	method := fullMethod[idx+1:]

	// If it is a version method we don't negotiate versions at all.
	if method == "GetVersionInfo" {
		return protocolversion.Invalid, false
	}

	// Determine what API is being called
	typ := protocolversion.Api
	if strings.HasPrefix(method, "Entrypoint") {
		typ = protocolversion.Entrypoint
	}

	return typ, true
}

// versionContext
func versionContext(
	ctx context.Context,
	typ protocolversion.Type,
	info *vagrant_server.VersionInfo,
) (context.Context, error) {
	var header string
	var server *vagrant_server.VersionInfo_ProtocolVersion
	switch typ {
	case protocolversion.Api:
		header = protocolversion.HeaderClientApiProtocol
		server = info.Api

	case protocolversion.Entrypoint:
		header = protocolversion.HeaderClientEntrypointProtocol
		server = info.Entrypoint

	default:
		return nil, status.Errorf(codes.Internal, "invalid protocol type")
	}

	// Get our metadata
	md, ok := metadata.FromIncomingContext(ctx)
	if !ok {
		return nil, status.Errorf(codes.InvalidArgument, "Retrieving metadata is failed")
	}

	// Get the client version information
	vs := md[header]
	if len(vs) != 1 {
		return nil, status.Errorf(codes.InvalidArgument,
			"required header %s is not set", header)
	}
	min, current, err := protocolversion.ParseHeader(vs[0])
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument,
			"header %q: %s", header, err)
	}

	// Negotiate the version to use
	version, err := protocolversion.Negotiate(&vagrant_server.VersionInfo_ProtocolVersion{
		Current: current,
		Minimum: min,
	}, server)
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument,
			"header %q: %s", header, err)
	}

	// Invoke the handler.
	return protocolversion.WithContext(ctx, version), nil
}

type versionStream struct {
	grpc.ServerStream
	context context.Context
}

func (s *versionStream) Context() context.Context {
	return s.context
}
