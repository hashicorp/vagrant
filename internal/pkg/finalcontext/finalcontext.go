// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// Package finalcontext is used by Vagrant to create a "final" context
// that we'll use after the real context has been cancelled. This lets us
// do some last minute cleanup that may require a context.
//
// For more detail in case that isn't clear: we use contexts everywhere
// for cancellation. Once cancelled, we may want to perform some cleanup,
// such as calling an RPC call to note we're cancelled. But this RPC itself
// requires a context and our context is already cancelled. We construct a
// "final" context that lets us do this.
package finalcontext

import (
	"context"
	"time"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant/internal/pkg/signalcontext"
)

// Context returns a final context. This context is set to timeout in
// some set amount of time (a few seconds) and will also cancel immediately
// if another interrupt is received.
func Context(log hclog.Logger) (context.Context, func()) {
	log.Warn("context cancelled, creating a final context to perform cleanup")

	ctx := context.Background()

	// Create a context that listens for another interrupt
	ctx, cancelSignal := signalcontext.WithInterrupt(ctx, log)

	// Create a timeout
	ctx, cancelTimeout := context.WithTimeout(ctx, 2*time.Second)

	return ctx, func() {
		cancelSignal()
		cancelTimeout()
	}
}
