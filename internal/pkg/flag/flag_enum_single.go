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
type EnumSingleVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Values     []string
	Default    string
	Hidden     bool
	EnvVar     string
	Target     *string
	SetHook    func(val string)
	Completion complete.Predictor
}

func (f *Set) EnumSingleVar(i *EnumSingleVar) {
	initial := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		initial = v
	}

	def := i.Default

	possible := strings.Join(i.Values, ", ")

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      strings.TrimRight(i.Usage, ". \t") + ". One possible value from: " + possible + ".",
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newEnumSingleValue(i, initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type enumSingleValue struct {
	ev     *EnumSingleVar
	hidden bool
	target *string
}

func newEnumSingleValue(ev *EnumSingleVar, def string, target *string, hidden bool) *enumSingleValue {
	*target = def
	return &enumSingleValue{
		ev:     ev,
		hidden: hidden,
		target: target,
	}
}

func (s *enumSingleValue) Set(val string) error {
	for _, p := range s.ev.Values {
		if p == val {
			*s.target = val

			if s.ev.SetHook != nil {
				s.ev.SetHook(val)
			}

			return nil
		}
	}

	return fmt.Errorf("'%s' not valid. Must be one of: %s", val, strings.Join(s.ev.Values, ", "))
}

func (s *enumSingleValue) Get() interface{} { return *s.target }
func (s *enumSingleValue) String() string   { return *s.target }
func (s *enumSingleValue) Example() string  { return "string" }
func (s *enumSingleValue) Hidden() bool     { return s.hidden }
