// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package protocolversion

import (
	"errors"
	"strings"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

var (
	ErrClientOutdated = errors.New(strings.TrimSpace(`
The client's supported protocol version is not understood by the server.

This means that the client is too outdated for the server. To solve this,
the client must be upgraded to a newer version.
`))

	ErrServerOutdated = errors.New(strings.TrimSpace(`
The server's minimum advertised protocol version is too outdated for the client.

This means that the client being run is newer than the server and the
API has changed significantly enough that this client can no longer communicate
to this server.

To solve this, either downgrade the client or upgrade the server. Please read
any upgrade guides prior to doing this to ensure a safe transition.
`))
)

// Negotiate takes two protocol versions and determines the value to use.
// If negotiation is impossible, an error is returned. The error value is
// one of the exported variables in this file.
func Negotiate(client, server *vagrant_server.VersionInfo_ProtocolVersion) (uint32, error) {
	// If the client is too old, then it is an error
	if client.Current < server.Minimum {
		return 0, ErrClientOutdated
	}

	// If the server is too old, also an error
	if server.Current < client.Minimum {
		return 0, ErrServerOutdated
	}

	// Determine our shared protocol number. We use the maximum protocol
	// that we both support.
	version := server.Current
	if version > client.Current {
		version = client.Current
	}

	return version, nil
}
