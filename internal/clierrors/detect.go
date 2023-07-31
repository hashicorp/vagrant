// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package clierrors

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// IsCanceled is true if the error represents a cancellation. This detects
// context cancellation as well as gRPC cancellation codes.
func IsCanceled(err error) bool {
	if err == context.Canceled {
		return true
	}

	s, ok := status.FromError(err)
	if !ok {
		return false
	}

	return s.Code() == codes.Canceled
}
