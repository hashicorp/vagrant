package communicator

import (
	"context"
	"fmt"
	"io"
	"os"
	"sync/atomic"
	"time"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

type Communicator interface {
	Connect() error
	Disconnect() error
	Timeout() time.Duration
	Start(*Cmd) error
	Download(path string, output io.Writer) error
	DownloadDir(dst, src string, excludes []string) error
	Upload(dst string, src io.Reader, srcinfo *os.FileInfo) error
	UploadDir(dst, src string, excludes []string) error
}

// maxBackoffDelay is the maximum delay between retry attempts
var maxBackoffDelay = 20 * time.Second
var initialBackoffDelay = time.Second
var logger = vagrant.DefaultLogger().Named("communicator")

// Fatal is an interface that error values can return to halt Retry
type Fatal interface {
	FatalError() error
}

// Retry retries the function f until it returns a nil error, a Fatal error, or
// the context expires.
func Retry(ctx context.Context, f func() error) error {
	// container for atomic error value
	type errWrap struct {
		E error
	}

	// Try the function in a goroutine
	var errVal atomic.Value
	doneCh := make(chan struct{})
	go func() {
		defer close(doneCh)

		delay := time.Duration(0)
		for {
			// If our context ended, we want to exit right away.
			select {
			case <-ctx.Done():
				return
			case <-time.After(delay):
			}

			// Try the function call
			err := f()

			// return if we have no error, or a FatalError
			done := false
			switch e := err.(type) {
			case nil:
				done = true
			case Fatal:
				err = e.FatalError()
				done = true
			}

			errVal.Store(errWrap{err})

			if done {
				return
			}

			logger.Warn("retryable error", "error", err)

			delay *= 2

			if delay == 0 {
				delay = initialBackoffDelay
			}

			if delay > maxBackoffDelay {
				delay = maxBackoffDelay
			}

			logger.Info("sleeping for retry", "duration", delay)
		}
	}()

	// Wait for completion
	select {
	case <-ctx.Done():
	case <-doneCh:
	}

	var lastErr error
	// Check if we got an error executing
	if ev, ok := errVal.Load().(errWrap); ok {
		lastErr = ev.E
	}

	// Check if we have a context error to check if we're interrupted or timeout
	switch ctx.Err() {
	case context.Canceled:
		return fmt.Errorf("interrupted - last error: %v", lastErr)
	case context.DeadlineExceeded:
		return fmt.Errorf("timeout - last error: %v", lastErr)
	}

	if lastErr != nil {
		return lastErr
	}
	return nil
}
