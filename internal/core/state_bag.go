// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"github.com/hashicorp/vagrant-plugin-sdk/core"
)

// The StateBag keeps the state of Vagrant during execution
type StateBag struct {
	state map[string]interface{}
}

func NewStateBag() *StateBag {
	return &StateBag{
		state: map[string]interface{}{},
	}
}

// Get implements core.StateBag
func (s *StateBag) Get(key string) interface{} {
	return s.state[key]
}

// GetOk implements core.StateBag
func (s *StateBag) GetOk(key string) (val interface{}, ok bool) {
	val, ok = s.state[key]
	return
}

// Put implements core.StateBag
func (s *StateBag) Put(key string, val interface{}) {
	s.state[key] = val
}

// Remove implements core.StateBag
func (s *StateBag) Remove(key string) {
	delete(s.state, key)
}

var _ core.StateBag = (*StateBag)(nil)
