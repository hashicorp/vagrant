// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// +build windows

package execclient

import "os"

func registerSigwinch(chan os.Signal) {
	// NOTE(mitchellh): we should use Windows APIs to poll the window size
}
