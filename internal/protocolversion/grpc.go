// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package protocolversion

import (
	"context"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// UnaryClientInterceptor returns an interceptor for the client to set
// the proper headers based on the attached VersionInfo. The VersionInfo is
// misnamed in this case and represents the client info.
func UnaryClientInterceptor(serverInfo *vagrant_server.VersionInfo) grpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		req, reply interface{},
		cc *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		opts ...grpc.CallOption) error {
		ctx = metadata.AppendToOutgoingContext(ctx,
			HeaderClientApiProtocol, EncodeHeader(
				serverInfo.Api.Minimum, serverInfo.Api.Current),
			HeaderClientEntrypointProtocol, EncodeHeader(
				serverInfo.Entrypoint.Minimum, serverInfo.Entrypoint.Current),
			HeaderClientVersion, serverInfo.Version,
		)

		return invoker(ctx, method, req, reply, cc, opts...)
	}
}

// StreamClientInterceptor returns an interceptor for the client to set
// the proper headers for stream APIs.
func StreamClientInterceptor(serverInfo *vagrant_server.VersionInfo) grpc.StreamClientInterceptor {
	return func(
		ctx context.Context,
		desc *grpc.StreamDesc,
		cc *grpc.ClientConn,
		method string,
		streamer grpc.Streamer,
		opts ...grpc.CallOption) (grpc.ClientStream, error) {
		ctx = metadata.AppendToOutgoingContext(ctx,
			HeaderClientApiProtocol, EncodeHeader(
				serverInfo.Api.Minimum, serverInfo.Api.Current),
			HeaderClientEntrypointProtocol, EncodeHeader(
				serverInfo.Entrypoint.Minimum, serverInfo.Entrypoint.Current),
			HeaderClientVersion, serverInfo.Version,
		)

		return streamer(ctx, desc, cc, method, opts...)
	}
}
