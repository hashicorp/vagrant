// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package clierrors

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestIsCanceled(t *testing.T) {
	t.Run("nil", func(t *testing.T) {
		var err error
		require.False(t, IsCanceled(err))
	})

	t.Run("context", func(t *testing.T) {
		ctx, cancel := context.WithCancel(context.Background())
		cancel()
		require.True(t, IsCanceled(ctx.Err()))
	})

	t.Run("status canceled", func(t *testing.T) {
		require.True(t, IsCanceled(status.Errorf(codes.Canceled, "")))
	})

	t.Run("status other", func(t *testing.T) {
		require.False(t, IsCanceled(status.Errorf(codes.FailedPrecondition, "")))
	})
}
