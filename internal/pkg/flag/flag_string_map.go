// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"fmt"
	"sort"
	"strings"

	"github.com/posener/complete"
)

// -- StringMapVar and stringMapValue
type StringMapVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    map[string]string
	Hidden     bool
	Target     *map[string]string
	Completion complete.Predictor
}

func (f *Set) StringMapVar(i *StringMapVar) {
	def := ""
	if i.Default != nil {
		def = mapToKV(i.Default)
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    def,
		Value:      newStringMapValue(i.Default, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type stringMapValue struct {
	hidden bool
	target *map[string]string
}

func newStringMapValue(def map[string]string, target *map[string]string, hidden bool) *stringMapValue {
	*target = def
	return &stringMapValue{
		hidden: hidden,
		target: target,
	}
}

func (s *stringMapValue) Set(val string) error {
	idx := strings.Index(val, "=")
	if idx == -1 {
		return fmt.Errorf("missing = in KV pair: %q", val)
	}

	if *s.target == nil {
		*s.target = make(map[string]string)
	}

	k, v := val[0:idx], val[idx+1:]
	(*s.target)[k] = v
	return nil
}

func (s *stringMapValue) Get() interface{} { return *s.target }
func (s *stringMapValue) String() string   { return mapToKV(*s.target) }
func (s *stringMapValue) Example() string  { return "key=value" }
func (s *stringMapValue) Hidden() bool     { return s.hidden }

func mapToKV(m map[string]string) string {
	list := make([]string, 0, len(m))
	for k := range m {
		list = append(list, k)
	}
	sort.Strings(list)

	for i, k := range list {
		list[i] = k + "=" + m[k]
	}

	return strings.Join(list, ",")
}
