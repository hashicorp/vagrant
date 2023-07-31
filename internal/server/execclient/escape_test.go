// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package execclient

// import (
// 	"bytes"
// 	"io"
// 	"io/ioutil"
// 	"testing"

// 	"github.com/stretchr/testify/assert"
// 	"github.com/stretchr/testify/require"
// )

// func TestEscape(t *testing.T) {
// 	t.Run("closes the context when the escape sequence is seen", func(t *testing.T) {
// 		var buf bytes.Buffer

// 		buf.WriteByte('\n')
// 		buf.WriteByte('~')
// 		buf.WriteByte('.')

// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: &buf}

// 		io.Copy(ioutil.Discard, ew)

// 		assert.True(t, ok, "context was not canceled")
// 	})

// 	t.Run("can see the sequence within a buffer", func(t *testing.T) {
// 		var buf bytes.Buffer

// 		buf.WriteString("hello")
// 		buf.WriteByte('\n')
// 		buf.WriteByte('~')
// 		buf.WriteByte('.')
// 		buf.WriteString("bye")

// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: &buf}

// 		io.Copy(ioutil.Discard, ew)

// 		assert.True(t, ok, "context was not canceled")
// 	})

// 	t.Run("can see the sequence across reads", func(t *testing.T) {
// 		r, w := io.Pipe()
// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: r}

// 		go w.Write([]byte("hello\n"))

// 		junk := make([]byte, 1024)

// 		n, err := ew.Read(junk)
// 		require.NoError(t, err)

// 		assert.Equal(t, 6, n)

// 		go w.Write([]byte("~."))

// 		n, err = ew.Read(junk)
// 		require.NoError(t, err)

// 		assert.Equal(t, 2, n)

// 		assert.True(t, ok, "context was not canceled")
// 	})

// 	t.Run("can see the sequence across reads split on ~ and .", func(t *testing.T) {
// 		r, w := io.Pipe()
// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: r}

// 		go w.Write([]byte("hello\n~"))

// 		junk := make([]byte, 1024)

// 		n, err := ew.Read(junk)
// 		require.NoError(t, err)

// 		assert.Equal(t, 7, n)

// 		go w.Write([]byte("."))

// 		n, err = ew.Read(junk)
// 		require.NoError(t, err)

// 		assert.Equal(t, 1, n)

// 		assert.True(t, ok, "context was not canceled")
// 	})

// 	t.Run("resets track state after newline", func(t *testing.T) {
// 		var buf bytes.Buffer

// 		buf.WriteString("\nx~.")

// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: &buf}

// 		io.Copy(ioutil.Discard, ew)

// 		assert.False(t, ok, "context was canceled")
// 		assert.Equal(t, escNormal, ew.state)
// 	})

// 	t.Run("resets track state after tilde", func(t *testing.T) {
// 		var buf bytes.Buffer

// 		buf.WriteString("\n~x.")

// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: &buf}

// 		io.Copy(ioutil.Discard, ew)

// 		assert.False(t, ok, "context was canceled")

// 		assert.Equal(t, escNormal, ew.state)
// 	})

// 	t.Run("follows newlines into escape state", func(t *testing.T) {
// 		var buf bytes.Buffer

// 		buf.WriteString("\n\n~.")

// 		var ok bool

// 		cancel := func() {
// 			ok = true
// 		}

// 		ew := &EscapeWatcher{Cancel: cancel, Input: &buf}

// 		io.Copy(ioutil.Discard, ew)

// 		assert.True(t, ok, "context was not canceled")
// 	})

// }
