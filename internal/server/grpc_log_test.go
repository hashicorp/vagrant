// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"bytes"
	"context"
	"testing"

	"github.com/hashicorp/go-hclog"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
)

func TestLogUnaryInterceptor(t *testing.T) {
	require := require.New(t)

	var buf bytes.Buffer
	logger := hclog.New(&hclog.LoggerOptions{
		Name:            "test",
		Level:           hclog.Debug,
		Output:          &buf,
		IncludeLocation: true,
	})

	f := logUnaryInterceptor(logger, false)

	// Empty context
	called := false
	resp, err := f(context.Background(), nil, &grpc.UnaryServerInfo{},
		func(ctx context.Context, req interface{}) (interface{}, error) {
			called = true
			reqLogger := hclog.FromContext(ctx)
			require.Equal(reqLogger, logger)
			return "hello", nil
		},
	)
	require.True(called)
	require.Equal("hello", resp)
	require.NoError(err)

	called = false
	resp, err = f(context.Background(), nil, &grpc.UnaryServerInfo{},
		func(ctx context.Context, req interface{}) (interface{}, error) {
			called = true
			logger := hclog.FromContext(ctx)
			logger.Warn("warning")
			return "hello", nil
		},
	)
	require.True(called)
	require.Equal("hello", resp)
	require.NoError(err)
}
