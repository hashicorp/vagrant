// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package cap

import (
	"os"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

func WriteHello(ui terminal.UI) error {
	msg := "Hello from the write hello capability, compliments of the AlwaysTrue Host"
	ui.Output(msg)
	return nil
}

func WriteHelloToTempfile() error {
	msg := []byte("Hello from the write hello capability, compliments of the AlwaysTrue Host")
	err := os.WriteFile("/tmp/write_hello", msg, 0644)
	if err != nil {
		panic(err)
	}
	return nil
}
