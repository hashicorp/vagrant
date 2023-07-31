// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// Package circbufsync wraps armon/circbuf to be safe for concurrent
// read/write operations.
package circbufsync

import (
	"sync"

	"github.com/armon/circbuf"
)

// New creates a new synced circbuf.Buffer.
func New(buf *circbuf.Buffer) *Buffer {
	return &Buffer{buf: buf}
}

// Buffer implements a subset of the *circbuf.Buffer methods where each
// exposed method is safe for concurrent read/write access.
type Buffer struct {
	sync.Mutex
	buf *circbuf.Buffer
}

// Bytes mimics circbuf.Write
func (b *Buffer) Write(p []byte) (int, error) {
	b.Lock()
	defer b.Unlock()
	return b.buf.Write(p)
}

// Bytes mimics circbuf.Buffer
func (b *Buffer) Bytes() []byte {
	b.Lock()
	defer b.Unlock()
	bs := b.buf.Bytes()

	// We need to copy since Bytes MAY put us into an internal pointer.
	// We have no way to detect this unfortunately so we have to copy every time.
	result := make([]byte, len(bs))
	copy(result, bs)

	return result
}
