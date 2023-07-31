// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package protocolversion

import (
	"fmt"
	"io"
)

// Header keys.
const (
	HeaderClientApiProtocol        = "client-api-protocol"
	HeaderClientEntrypointProtocol = "client-entrypoint-protocol"
	HeaderClientVersion            = "client-version"
)

// ParseHeader parses header values containing minimum and current
// protocol version numbers. This returns an error if parsing fails for
// reason, including blank values.
func ParseHeader(v string) (uint32, uint32, error) {
	var min, current uint32
	n, err := fmt.Sscanf(v, "%d,%d", &min, &current)
	if err == io.EOF {
		n = 0
		err = nil
	}
	if err != nil {
		return 0, 0, err
	}
	if n != 2 {
		return 0, 0, fmt.Errorf("protocol version header must be formatted <min>,<current>")
	}

	return min, current, nil
}

// EncodeHeader creates a valid header value for the protocol version headers.
func EncodeHeader(min, current uint32) string {
	return fmt.Sprintf("%d,%d", min, current)
}
