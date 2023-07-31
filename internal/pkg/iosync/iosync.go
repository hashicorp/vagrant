// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// Package iosync provides reader/writer implementations that wrap
// operations in a mutex so that concurrent reads and writes are safe.
package iosync

import (
	"io"
	"sync"
)

// ReadWriter returns an io.ReadWriter where reading/writing concurrently is
// safe. Both read/write operations will share the same mutex. All operations
// are exclusive. We do not use a RWMutex because most io.Readers aren't
// inherently safe to concurrent read access.
func ReadWriter(rw io.ReadWriter) io.ReadWriter {
	var m sync.Mutex
	return &readWriter{
		Reader: &reader{
			Mutex:  &m,
			Reader: rw,
		},

		Writer: &writer{
			Mutex:  &m,
			Writer: rw,
		},
	}
}

type readWriter struct {
	io.Reader
	io.Writer
}

type writer struct {
	*sync.Mutex
	io.Writer
}

func (w *writer) Write(p []byte) (int, error) {
	w.Lock()
	defer w.Unlock()
	return w.Writer.Write(p)
}

type reader struct {
	*sync.Mutex
	io.Reader
}

func (r *reader) Read(p []byte) (int, error) {
	r.Lock()
	defer r.Unlock()
	return r.Reader.Read(p)
}

var (
	_ io.Reader     = (*reader)(nil)
	_ io.Writer     = (*writer)(nil)
	_ io.ReadWriter = (*readWriter)(nil)
)
