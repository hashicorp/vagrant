// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package main

import (
	"os"
	"path/filepath"

	"github.com/hashicorp/vagrant/internal/cli"
)

func main() {
	// Make args[0] just the name of the executable since it is used in logs.
	os.Args[0] = filepath.Base(os.Args[0])

	os.Exit(cli.Main(os.Args))
}
