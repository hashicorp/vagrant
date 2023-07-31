// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package clierrors

import (
	"github.com/mitchellh/go-wordwrap"
	"google.golang.org/grpc/status"
)

func Humanize(err error) string {
	if err == nil {
		return ""
	}

	if IsCanceled(err) {
		return "operation canceled"
	}

	v := err.Error()
	if s, ok := status.FromError(err); ok {
		v = s.Message()
	}

	return wordwrap.WrapString(v, 80)
}
