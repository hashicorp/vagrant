// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"strings"
)

// labelsMerge is a basic map merge method. This will ignore any nil maps.
func labelsMerge(ls ...map[string]string) map[string]string {
	if len(ls) == 0 {
		return nil
	}

	result := map[string]string{}
	for _, l := range ls {
		for k, v := range l {
			result[k] = v
		}
	}

	return result
}

// labelsStripPrefix deletes all labels that have the specified prefix for
// the key. The prefix must end with "/".
func labelsStripPrefix(ls map[string]string, prefix string) map[string]string {
	if !strings.HasSuffix(prefix, "/") {
		prefix += "/"
	}

	for k := range ls {
		if strings.HasPrefix(k, prefix) {
			delete(ls, k)
		}
	}

	return ls
}
