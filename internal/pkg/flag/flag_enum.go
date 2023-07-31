// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"fmt"
	"os"
	"strings"

	"github.com/posener/complete"
)

// -- EnumVar and enumValue
type EnumVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Values     []string
	Default    []string
	Hidden     bool
	EnvVar     string
	Target     *[]string
	Completion complete.Predictor
}

func (f *Set) EnumVar(i *EnumVar) {
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

	possible := strings.Join(i.Values, ", ")

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      strings.TrimRight(i.Usage, ". \t") + ". One possible value from: " + possible + ".",
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newEnumValue(i, initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type enumValue struct {
	ev     *EnumVar
	hidden bool
	target *[]string
}

func newEnumValue(ev *EnumVar, def []string, target *[]string, hidden bool) *enumValue {
	*target = def
	return &enumValue{
		ev:     ev,
		hidden: hidden,
		target: target,
	}
}

func (s *enumValue) Set(vals string) error {
	parts := strings.Split(vals, ",")

parts:
	for _, val := range parts {
		val = strings.TrimSpace(val)

		for _, p := range s.ev.Values {
			if p == val {
				*s.target = append(*s.target, strings.TrimSpace(val))
				continue parts
			}
		}

		return fmt.Errorf("'%s' not valid. Must be one of: %s", val, strings.Join(s.ev.Values, ", "))
	}

	return nil
}

func (s *enumValue) Get() interface{} { return *s.target }
func (s *enumValue) String() string   { return strings.Join(*s.target, ",") }
func (s *enumValue) Example() string  { return "string" }
func (s *enumValue) Hidden() bool     { return s.hidden }
