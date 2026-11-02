// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package serverclient

import (
	"context"
	"time"

	"github.com/hashicorp/go-hclog"
	"google.golang.org/grpc"
)

// logUnaryInterceptor returns a gRPC unary interceptor that inserts a hclog.Logger
// into the request context.
//
// Additionally, logUnaryInterceptor logs request and response metadata. If verbose
// is set to true, the request and response attributes are logged too.
func logClientUnaryInterceptor(logger hclog.Logger, verbose bool) grpc.UnaryClientInterceptor {
	return func(
		ctx context.Context,
		method string,
		req interface{},
		reply interface{},
		cc *grpc.ClientConn,
		invoker grpc.UnaryInvoker,
		opts ...grpc.CallOption) error {
		start := time.Now()

		// Log the request.
		{
			var reqLogArgs []interface{}
			// Log the request's attributes only if verbose is set to true.
			if verbose {
				reqLogArgs = append(reqLogArgs, "request", req)
			}
			logger.Info(method+" request", reqLogArgs...)
		}

		// Invoke the handler.
		ctx = hclog.WithContext(ctx, logger)
		err := invoker(ctx, method, req, reply, cc, opts...)

		// Log the response.
		{
			respLogArgs := []interface{}{
				"error", err,
				"duration", time.Since(start).String(),
			}
			// Log the response's attributes only if verbose is set to true.
			if verbose {
				respLogArgs = append(respLogArgs, "response", reply)
			}
			logger.Info(method+" response", respLogArgs...)
		}

		return err
	}
}
