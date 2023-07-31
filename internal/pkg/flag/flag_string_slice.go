// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"os"
	"strings"

	"github.com/posener/complete"
)

// -- StringSliceVar and stringSliceValue
type StringSliceVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    []string
	Hidden     bool
	EnvVar     string
	Target     *[]string
	Completion complete.Predictor
}

func (f *Set) StringSliceVar(i *StringSliceVar) {
	initial := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		parts := strings.Split(v, ",")
		for i := range parts {
			parts[i] = strings.TrimSpace(parts[i])
		}
		initial = parts
	}

	def := ""
	if i.Default != nil {
		def = strings.Join(i.Default, ",")
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newStringSliceValue(initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type stringSliceValue struct {
	hidden bool
	target *[]string
	set    bool
}

func newStringSliceValue(def []string, target *[]string, hidden bool) *stringSliceValue {
	*target = def
	return &stringSliceValue{
		hidden: hidden,
		target: target,
	}
}

func (s *stringSliceValue) Set(val string) error {
	if !s.set {
		s.set = true
		*s.target = nil
	}

	*s.target = append(*s.target, strings.TrimSpace(val))
	return nil
}

func (s *stringSliceValue) Get() interface{} { return *s.target }
func (s *stringSliceValue) String() string   { return strings.Join(*s.target, ",") }
func (s *stringSliceValue) Example() string  { return "string" }
func (s *stringSliceValue) Hidden() bool     { return s.hidden }
