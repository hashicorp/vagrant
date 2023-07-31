// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package protocolversion

import (
	"context"
)

type contextKeyType string

// WithContext stores the protocol version in the context.
func WithContext(ctx context.Context, vsn uint32) context.Context {
	return context.WithValue(ctx, contextKeyType("version"), vsn)
}

// FromContext retrieves the protocol version from the context, or returns
// zero if no version was present.
func FromContext(ctx context.Context) uint32 {
	v, ok := ctx.Value(contextKeyType("version")).(uint32)
	if !ok {
		v = 0
	}

	return v
}
