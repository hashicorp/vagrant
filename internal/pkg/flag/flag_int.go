// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flag

import (
	"os"
	"strconv"

	"github.com/posener/complete"
)

// -- IntVar and intValue
type IntVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    int
	Hidden     bool
	EnvVar     string
	Target     *int
	Completion complete.Predictor
	SetHook    func(val int)
}

func (f *Set) IntVar(i *IntVar) {
	initial := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		if i, err := strconv.ParseInt(v, 0, 64); err == nil {
			initial = int(i)
		}
	}

	def := ""
	if i.Default != 0 {
		def = strconv.FormatInt(int64(i.Default), 10)
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newIntValue(i, initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type intValue struct {
	v      *IntVar
	hidden bool
	target *int
}

func newIntValue(v *IntVar, def int, target *int, hidden bool) *intValue {
	*target = def
	return &intValue{
		v:      v,
		hidden: hidden,
		target: target,
	}
}

func (i *intValue) Set(s string) error {
	v, err := strconv.ParseInt(s, 0, 64)
	if err != nil {
		return err
	}

	*i.target = int(v)

	if i.v.SetHook != nil {
		i.v.SetHook(int(v))
	}

	return nil
}

func (i *intValue) Get() interface{} { return int(*i.target) }
func (i *intValue) String() string   { return strconv.Itoa(int(*i.target)) }
func (i *intValue) Example() string  { return "int" }
func (i *intValue) Hidden() bool     { return i.hidden }

// -- Int64Var and int64Value
type Int64Var struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    int64
	Hidden     bool
	EnvVar     string
	Target     *int64
	Completion complete.Predictor
	SetHook    func(val int64)
}

func (f *Set) Int64Var(i *Int64Var) {
	initial := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		if i, err := strconv.ParseInt(v, 0, 64); err == nil {
			initial = i
		}
	}

	def := ""
	if i.Default != 0 {
		def = strconv.FormatInt(int64(i.Default), 10)
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newInt64Value(i, initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type int64Value struct {
	v      *Int64Var
	hidden bool
	target *int64
}

func newInt64Value(v *Int64Var, def int64, target *int64, hidden bool) *int64Value {
	*target = def
	return &int64Value{
		v:      v,
		hidden: hidden,
		target: target,
	}
}

func (i *int64Value) Set(s string) error {
	v, err := strconv.ParseInt(s, 0, 64)
	if err != nil {
		return err
	}

	*i.target = v

	if i.v.SetHook != nil {
		i.v.SetHook(v)
	}

	return nil
}

func (i *int64Value) Get() interface{} { return int64(*i.target) }
func (i *int64Value) String() string   { return strconv.FormatInt(int64(*i.target), 10) }
func (i *int64Value) Example() string  { return "int" }
func (i *int64Value) Hidden() bool     { return i.hidden }

// -- UintVar && uintValue
type UintVar struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    uint
	Hidden     bool
	EnvVar     string
	Target     *uint
	Completion complete.Predictor
	SetHook    func(val uint)
}

func (f *Set) UintVar(i *UintVar) {
	initial := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		if i, err := strconv.ParseUint(v, 0, 64); err == nil {
			initial = uint(i)
		}
	}

	def := ""
	if i.Default != 0 {
		def = strconv.FormatUint(uint64(i.Default), 10)
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newUintValue(i, initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type uintValue struct {
	v      *UintVar
	hidden bool
	target *uint
}

func newUintValue(v *UintVar, def uint, target *uint, hidden bool) *uintValue {
	*target = def
	return &uintValue{
		v:      v,
		hidden: hidden,
		target: target,
	}
}

func (i *uintValue) Set(s string) error {
	v, err := strconv.ParseUint(s, 0, 64)
	if err != nil {
		return err
	}

	*i.target = uint(v)

	if i.v.SetHook != nil {
		i.v.SetHook(uint(v))
	}

	return nil
}

func (i *uintValue) Get() interface{} { return uint(*i.target) }
func (i *uintValue) String() string   { return strconv.FormatUint(uint64(*i.target), 10) }
func (i *uintValue) Example() string  { return "uint" }
func (i *uintValue) Hidden() bool     { return i.hidden }

// -- Uint64Var and uint64Value
type Uint64Var struct {
	Name       string
	Aliases    []string
	Usage      string
	Default    uint64
	Hidden     bool
	EnvVar     string
	Target     *uint64
	Completion complete.Predictor
	SetHook    func(val uint64)
}

func (f *Set) Uint64Var(i *Uint64Var) {
	initial := i.Default
	if v, exist := os.LookupEnv(i.EnvVar); exist {
		if i, err := strconv.ParseUint(v, 0, 64); err == nil {
			initial = i
		}
	}

	def := ""
	if i.Default != 0 {
		strconv.FormatUint(i.Default, 10)
	}

	f.VarFlag(&VarFlag{
		Name:       i.Name,
		Aliases:    i.Aliases,
		Usage:      i.Usage,
		Default:    def,
		EnvVar:     i.EnvVar,
		Value:      newUint64Value(i, initial, i.Target, i.Hidden),
		Completion: i.Completion,
	})
}

type uint64Value struct {
	v      *Uint64Var
	hidden bool
	target *uint64
}

func newUint64Value(v *Uint64Var, def uint64, target *uint64, hidden bool) *uint64Value {
	*target = def
	return &uint64Value{
		v:      v,
		hidden: hidden,
		target: target,
	}
}

func (i *uint64Value) Set(s string) error {
	v, err := strconv.ParseUint(s, 0, 64)
	if err != nil {
		return err
	}

	*i.target = v

	if i.v.SetHook != nil {
		i.v.SetHook(v)
	}

	return nil
}

func (i *uint64Value) Get() interface{} { return uint64(*i.target) }
func (i *uint64Value) String() string   { return strconv.FormatUint(uint64(*i.target), 10) }
func (i *uint64Value) Example() string  { return "uint" }
func (i *uint64Value) Hidden() bool     { return i.hidden }
