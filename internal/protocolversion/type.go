// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package protocolversion

//go:generate stringer -type=Type -linecomment

// Type is the enum of protocol version types.
type Type uint8

const (
	Invalid    Type = iota // invalid
	Api                    // api
	Entrypoint             // entrypoint
)
