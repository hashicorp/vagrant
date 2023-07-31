// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package sort

import (
	"sort"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// ConfigName sorts config variables by name.
type ConfigName []*vagrant_server.ConfigVar

func (s ConfigName) Len() int      { return len(s) }
func (s ConfigName) Swap(i, j int) { s[i], s[j] = s[j], s[i] }
func (s ConfigName) Less(i, j int) bool {
	return s[i].Name < s[j].Name
}

var (
	_ sort.Interface = (ConfigName)(nil)
)
