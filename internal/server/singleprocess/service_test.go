// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package singleprocess

import (
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func testServiceImpl(impl vagrant_server.VagrantServer) *service {
	return impl.(*service)
}
