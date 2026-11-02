// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
)

type trivialAuth struct {
	method  string
	token   string
	effects []string
}

// Called before each RPC to authenticate it.
func (t *trivialAuth) Authenticate(ctx context.Context, token string, endpoint string, effects []string) error {
	t.method = endpoint
	t.token = token
	t.effects = effects
	return nil
}

func TestAuthUnaryInterceptor(t *testing.T) {
	require := require.New(t)

	var chk trivialAuth

	f := authUnaryInterceptor(&chk)

	ctx := context.Background()

	tokenVal := "this-is-a-token"

	ctx = metadata.NewIncomingContext(ctx, metadata.MD{
		"authorization": []string{tokenVal},
	})

	// Empty context
	called := false
	resp, err := f(ctx, nil, &grpc.UnaryServerInfo{FullMethod: "/foo/bar"},
		func(ctx context.Context, req interface{}) (interface{}, error) {
			called = true
			return "hello", nil
		},
	)

	require.True(called)
	require.Equal("hello", resp)
	require.NoError(err)

	require.Equal(tokenVal, chk.token)
	require.Equal("bar", chk.method)
	require.Equal(DefaultEffects, chk.effects)
}
