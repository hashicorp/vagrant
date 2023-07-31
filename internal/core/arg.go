// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"github.com/hashicorp/go-argmapper"
	"google.golang.org/protobuf/types/known/anypb"
)

// argNamedAny returns an argmapper.Arg that specifies the Any value
// with the proper subtype.
func argNamedAny(n string, v *anypb.Any) argmapper.Arg {
	if v == nil {
		return nil
	}

	msg := string(v.MessageName())

	return argmapper.NamedSubtype(n, v, msg)
}
