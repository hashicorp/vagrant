// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package execclient

import (
	"io"
)

type EscapeWatcher struct {
	Cancel func()
	Input  io.Reader

	state int
}

const (
	escNormal = iota
	escNewline
	escTilde
)

func (ew *EscapeWatcher) Read(b []byte) (int, error) {
	n, err := ew.Input.Read(b)
	if err != nil {
		return n, err
	}

	for _, r := range b[:n] {
		switch ew.state {
		case escNewline:
			switch r {
			case '~':
				ew.state = escTilde
			case '\n':
				ew.state = escNewline
			default:
				ew.state = escNormal
			}
		case escTilde:
			if r == '.' {
				ew.Cancel()
			} else {
				ew.state = escNormal
			}
		case escNormal:
			if r == '\n' {
				ew.state = escNewline
			}
		}
	}

	return n, nil
}
