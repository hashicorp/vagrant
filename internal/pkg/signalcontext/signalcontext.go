// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package signalcontext

import (
	"context"
	"os"
	"os/signal"

	"github.com/hashicorp/go-hclog"
)

// WithInterrupt returns a Context that is done when an interrupt signal is received.
// It also returns a closer function that should be deferred for proper cleanup.
func WithInterrupt(ctx context.Context, log hclog.Logger) (context.Context, func()) {
	log.Trace("starting interrupt listener for context cancellation")

	// Create the cancellable context that we'll use when we receive an interrupt
	ctx, cancel := context.WithCancel(ctx)

	// Create the signal channel and cancel the context when we get a signal
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt)
	go func() {
		log.Trace("interrupt listener goroutine started")

		select {
		case <-ch:
			log.Warn("interrupt received, cancelling context")
			cancel()
		case <-ctx.Done():
			log.Warn("context cancelled, stopping interrupt listener loop")
			return
		}
	}()

	// Return the context and a closer that cancels the context and also
	// stops any signals from coming to our channel.
	return ctx, func() {
		log.Trace("stopping signal listeners and cancelling the context")
		signal.Stop(ch)
		cancel()
	}
}
