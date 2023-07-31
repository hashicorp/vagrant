// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"os"
	"strconv"

	"github.com/posener/complete"
)

// -- BoolVar  and boolValue
type BoolVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    bool
	Hidden     bool
	EnvVar     string
	Target     *bool
	Completion complete.Predictor
	SetHook    func(val bool)
}

func (f *Set) BoolVar(i *BoolVar) {
	def := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		if b, err := strconv.ParseBool(v); err == nil {
			def = b
		}
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    strconv.FormatBool(i.Default),
		EnvVar:     i.EnvVar,
		Value:      newBoolValue(i, def, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type boolValue struct {
	v      *BoolVar
	hidden bool
	target *bool
}

func newBoolValue(v *BoolVar, def bool, target *bool, hidden bool) *boolValue {
	*target = def

	return &boolValue{
		v:      v,
		hidden: hidden,
		target: target,
	}
}

func (b *boolValue) Set(s string) error {
	v, err := strconv.ParseBool(s)
	if err != nil {
		return err
	}

	*b.target = v

	if b.v.SetHook != nil {
		b.v.SetHook(v)
	}

	return nil
}

func (b *boolValue) Get() interface{} { return *b.target }
func (b *boolValue) String() string   { return strconv.FormatBool(*b.target) }
func (b *boolValue) Example() string  { return "" }
func (b *boolValue) Hidden() bool     { return b.hidden }
func (b *boolValue) IsBoolFlag() bool { return true }
