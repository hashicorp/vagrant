// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

// +build !windows

package execclient

import (
	"os"
	"os/signal"

	"golang.org/x/sys/unix"
)

func registerSigwinch(winchCh chan os.Signal) {
	signal.Notify(winchCh, unix.SIGWINCH)
}
