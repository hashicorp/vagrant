// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package protocolversion

import (
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/version"
)

//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//
// Protocol Versions
//
// These define the protocol versions supported by the server. You must be
// VERY THOUGHTFUL when modifying these values. Please read and re-read our
// upgrade policy to understand how these values work.
//
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
const (
	protocolVersionApiCurrent        uint32 = 1
	protocolVersionApiMin                   = 1
	protocolVersionEntrypointCurrent uint32 = 1
	protocolVersionEntrypointMin            = 1
)

// Current returns the current protocol version information.
func Current() *vagrant_server.VersionInfo {
	return &vagrant_server.VersionInfo{
		Api: &vagrant_server.VersionInfo_ProtocolVersion{
			Current: protocolVersionApiCurrent,
			Minimum: protocolVersionApiMin,
		},

		Entrypoint: &vagrant_server.VersionInfo_ProtocolVersion{
			Current: protocolVersionEntrypointCurrent,
			Minimum: protocolVersionEntrypointMin,
		},

		Version: version.GetVersion().VersionNumber(),
	}
}
