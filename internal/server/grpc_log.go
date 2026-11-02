// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"context"
	"time"

	"github.com/hashicorp/go-hclog"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

// logUnaryInterceptor returns a gRPC unary interceptor that inserts a hclog.Logger
// into the request context.
//
// Additionally, logUnaryInterceptor logs request and response metadata. If verbose
// is set to true, the request and response attributes are logged too.
func logUnaryInterceptor(logger hclog.Logger, verbose bool) grpc.UnaryServerInterceptor {
	return func(
		ctx context.Context,
		req interface{},
		info *grpc.UnaryServerInfo,
		handler grpc.UnaryHandler) (interface{}, error) {
		start := time.Now()

		// Log the request.
		{
			var reqLogArgs []interface{}

			md, ok := metadata.FromIncomingContext(ctx)
			if ok {
				reqLogArgs = append(reqLogArgs, "metadata", md)
			}
			// Log the request's attributes only if verbose is set to true.
			if verbose {
				reqLogArgs = append(reqLogArgs, "request", req)
			}
			logger.Info(info.FullMethod+" request", reqLogArgs...)
		}

		// Invoke the handler.
		ctx = hclog.WithContext(ctx, logger)
		resp, err := handler(ctx, req)

		// Log the response.
		{
			respLogArgs := []interface{}{
				"error", err,
				"duration", time.Since(start).String(),
			}
			// Log the response's attributes only if verbose is set to true.
			if verbose {
				respLogArgs = append(respLogArgs, "response", resp)
			}
			logger.Info(info.FullMethod+" response", respLogArgs...)
		}

		return resp, err
	}
}

// TODO(spox): make a client stream interceptor for ruby runtime

// logUnaryInterceptor returns a gRPC unary interceptor that inserts a hclog.Logger
// into the request context.
//
// Additionally, logUnaryInterceptor logs request and response metadata. If verbose
// is set to true, the request and response attributes are logged too.
func logStreamInterceptor(logger hclog.Logger, verbose bool) grpc.StreamServerInterceptor {
	return func(
		srv interface{},
		ss grpc.ServerStream,
		info *grpc.StreamServerInfo,
		handler grpc.StreamHandler) error {
		start := time.Now()

		// Log the request.
		logger.Info(info.FullMethod + " request")

		// Invoke the handler.
		err := handler(srv, &logStream{
			ServerStream: ss,
			context:      hclog.WithContext(ss.Context(), logger),
		})

		// Log the response.
		logger.Info(info.FullMethod+" response",
			"error", err,
			"duration", time.Since(start).String(),
		)

		return err
	}
}

type logStream struct {
	grpc.ServerStream
	context context.Context
}

func (s *logStream) Context() context.Context {
	return s.context
}
