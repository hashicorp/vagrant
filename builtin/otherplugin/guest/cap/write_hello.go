// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package cap

import (
	"io/ioutil"

	plugincore "github.com/hashicorp/vagrant-plugin-sdk/core"
)

func WriteHello(machine plugincore.Machine) (err error) {
	d1 := []byte("hello\ngo\n")
	ioutil.WriteFile("/tmp/dat1", d1, 0644)

	machine.ConnectionInfo()
	// TODO: write something to guest machine
	// need a communicator
	return
}
