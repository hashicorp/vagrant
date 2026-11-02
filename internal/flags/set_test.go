// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flags

import (
	"fmt"
	"strings"
	"testing"
)

func Test_NewSet(t *testing.T) {
	s := testSet()
	if s.name != "testing-set" {
		t.Errorf("invalid name - testing-set != %s", s.name)
	}
	if len(s.groups) < 1 {
		t.Fatalf("default group does not exist")
	}
	if s.groups[0].name != INTERNAL_GROUP_NAME {
		t.Errorf("invalid default group - %s != %s", INTERNAL_GROUP_NAME, s.groups[0].name)
	}
}

func Test_SetErrorMode(t *testing.T) {
	s := testSet()
	if s.errorHandling != ReturnOnError {
		t.Errorf("invalid error handling - %d != %d", ReturnOnError, s.errorHandling)
	}
	SetErrorMode(PanicOnError)(s)
	if s.errorHandling != PanicOnError {
		t.Errorf("invalid error handling - %d != %d", PanicOnError, s.errorHandling)
	}
}

func Test_SetUnknownMode(t *testing.T) {
	s := testSet()
	if s.unknownHandling != ErrorOnUnknown {
		t.Errorf("invalid unknown handling - %d != %d", ErrorOnUnknown, s.unknownHandling)
	}
	SetUnknownMode(PassOnUnknown)(s)
	if s.unknownHandling != PassOnUnknown {
		t.Errorf("invalid unknown handling - %d != %d", PassOnUnknown, s.unknownHandling)
	}
}

func Test_Set_Name(t *testing.T) {
	s := testSet()
	s.name = "my-set"
	if s.Name() != "my-set" {
		t.Errorf("invalid name - my-set != %s", s.Name())
	}
}

func Test_Set_Groups(t *testing.T) {
	s := testSet()
	if len(s.Groups()) != 1 {
		t.Fatalf("invalid groups length - 1 != %d", len(s.Groups()))
	}
}

func Test_Set_Visit(t *testing.T) {
	s := testSet()
	g := s.groups[0]
	for i := 0; i < 5; i++ {
		f := testFlag(g)
		f.longName = fmt.Sprintf("test-flag-%d", i)
		if i > 2 {
			f.updated = true
		}
		if i > 3 {
			f.called = true
		}
	}
	seen := []string{}
	s.Visit(func(f *Flag) {
		seen = append(seen, f.longName)
	})
	if len(seen) != 2 {
		t.Errorf("invalid number of flags seen - 2 != %d", len(seen))
	}
}

func Test_Set_VisitCalled(t *testing.T) {
	s := testSet()
	g := s.groups[0]
	for i := 0; i < 5; i++ {
		f := testFlag(g)
		f.longName = fmt.Sprintf("test-flag-%d", i)
		if i > 2 {
			f.updated = true
		}
		if i > 3 {
			f.called = true
		}
	}
	seen := []string{}
	s.VisitCalled(func(f *Flag) {
		seen = append(seen, f.longName)
	})
	if len(seen) != 1 {
		t.Errorf("invalid number of flags seen - 1 != %d", len(seen))
	}
}

func Test_Set_VisitAll(t *testing.T) {
	s := testSet()
	g := s.groups[0]
	for i := 0; i < 5; i++ {
		f := testFlag(g)
		f.longName = fmt.Sprintf("test-flag-%d", i)
		if i > 2 {
			f.updated = true
		}
		if i > 3 {
			f.called = true
		}
	}
	seen := []string{}
	s.VisitAll(func(f *Flag) {
		seen = append(seen, f.longName)
	})
	if len(seen) != 5 {
		t.Errorf("invalid number of flags seen - 5 != %d", len(seen))
	}
}

func Test_Set_CreateGroup(t *testing.T) {
	s := testSet()
	if _, err := s.NewGroup("test-group"); err != nil {
		t.Fatalf("failed to create new group: %s", err)
	}
	if len(s.groups) != 2 {
		t.Fatalf("invalid groups length - 2 != %d", len(s.groups))
	}
	if s.groups[1].name != "test-group" {
		t.Errorf("invalid group name - test-group != %s", s.groups[1].name)
	}
}

func Test_Set_CreateGroup_duplicate(t *testing.T) {
	n := "test-group-name"
	s := testSet()
	if _, err := s.NewGroup(n); err != nil {
		t.Fatalf("failed to create new group: %s", err)
	}
	if _, err := s.NewGroup(n); err == nil {
		t.Fatalf("expected error but no error returned")
	}
}

func Test_Set_DefaultGroup(t *testing.T) {
	s := testSet()
	if s.DefaultGroup().name != INTERNAL_GROUP_NAME {
		t.Errorf("invalid default group name - %s != %s", INTERNAL_GROUP_NAME, s.name)
	}
}

func Test_Set_Flags(t *testing.T) {
	s := testSet()
	if _, err := s.NewGroup("test-group"); err != nil {
		t.Fatalf("failed to create new group: %s", err)
	}
	for i := 0; i < 5; i++ {
		testFlag(s.groups[0])
		testFlag(s.groups[1])
	}
	if len(s.Flags()) != 10 {
		t.Errorf("invalid flags length - 10 != %d", len(s.Flags()))
	}
}

func Test_Set_Parse(t *testing.T) {
	s := testSet()
	r, err := s.Parse([]string{})
	if len(r) != 0 {
		t.Errorf("invalid remaining args - 0 != %d", len(r))
	}
	if err != nil {
		t.Errorf("unexpected parse error: %s", err)
	}
}

func Test_Set_Parse_no_flags(t *testing.T) {
	s := testSet()
	r, err := s.Parse([]string{"some-arg"})
	if err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if len(r) != 1 {
		t.Fatalf("invalid remaining args - 1 != %d", len(r))
	}
	if r[0] != "some-arg" {
		t.Errorf("invalid remaining value - some-arg != %s", r[0])
	}
}

func Test_Set_Parse_multi_error(t *testing.T) {
	s := testSet()
	if _, err := s.Parse([]string{}); err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if _, err := s.Parse([]string{}); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_Parse_multi_panic(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("expected panic but no panic recovered")
		}
	}()
	s := testSet()
	s.errorHandling = PanicOnError
	if _, err := s.Parse([]string{}); err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if _, err := s.Parse([]string{}); err != nil {
		t.Errorf("expected panic from parse but received error: %s", err)
	}
}

func Test_Set_Parse_single_bool(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	r, err := s.Parse([]string{"--mark"})
	if err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if len(r) > 0 {
		t.Errorf("invalid remaining args - 0 != %d", len(r))
	}
	if !s.Flags()[0].Value().(bool) {
		t.Errorf("invalid flag value - true != false")
	}
}

func Test_Set_Parse_single_bool_extra_arg(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	r, err := s.Parse([]string{"--mark", "extra-arg"})
	if err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if len(r) != 1 {
		t.Fatalf("invalid remaining args length - 1 != %d", len(r))
	}
	if r[0] != "extra-arg" {
		t.Errorf("invalid remaining arg - extra-arg != %s", r[0])
	}
}

func Test_Set_flagNotFound(t *testing.T) {
	s := testSet()
	s.unknownHandling = ErrorOnUnknown
	if err := s.flagNotFound("mark"); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_flagNotFound_pass(t *testing.T) {
	s := testSet()
	s.unknownHandling = PassOnUnknown
	if err := s.flagNotFound("mark"); err != nil {
		t.Errorf("expected no error but error was returned: %s", err)
	}
}

func Test_Set_initFlags(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	s.DefaultGroup().String("entry")
	for _, f := range s.Flags() {
		if f.value != nil {
			t.Fatalf("expected value to be nil before init (%#v)", f.value)
		}
	}
	if err := s.initFlags(); err != nil {
		t.Fatalf("unexpected init error: %s", err)
	}
	for _, f := range s.Flags() {
		if f.value == nil {
			t.Errorf("flag value should not be nil - flag: %s", f.longName)
		}
	}
}

func Test_Set_initFlags_bool_negated(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	if err := s.initFlags(); err != nil {
		t.Fatalf("unexpected init error: %s", err)
	}
	if _, ok := s.flagMap["no-mark"]; !ok {
		t.Errorf("negated boolean flag not found")
	}
}

func Test_Set_initFlags_collision_long(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	s.DefaultGroup().String("mark")
	if err := s.initFlags(); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_initFlags_collision_short(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark", ShortName('m'))
	s.DefaultGroup().String("entry", ShortName('m'))
	if err := s.initFlags(); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_initFlags_collision_long_alias(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark", Alias("thing"))
	s.DefaultGroup().String("entry", Alias("thing"))
	if err := s.initFlags(); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_initFlags_collision_short_alias(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark", ShortName('m'))
	s.DefaultGroup().String("entry", Alias("m"))
	if err := s.initFlags(); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_initFlags_collision_bool_negate_long(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	s.DefaultGroup().String("no-mark")
	if err := s.initFlags(); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_Parse_unknown_error(t *testing.T) {
	s := testSet()
	s.unknownHandling = ErrorOnUnknown
	s.errorHandling = ReturnOnError
	s.DefaultGroup().Bool("mark")
	if _, err := s.Parse([]string{"--entry"}); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_Set_Parse_unknown_panic(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Fatalf("expected panic but no panic recovered")
		}
	}()
	s := testSet()
	s.unknownHandling = ErrorOnUnknown
	s.errorHandling = PanicOnError
	s.DefaultGroup().Bool("mark")
	s.Parse([]string{"--entry"})
}

func Test_Set_Parse_unknown_pass(t *testing.T) {
	s := testSet()
	s.unknownHandling = PassOnUnknown
	s.DefaultGroup().Bool("mark")
	r, err := s.Parse([]string{"--entry", "VALUE"})
	if err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if len(r) != 2 {
		t.Fatalf("invalid remaining length - 2 != %d", len(r))
	}
	if r[0] != "--entry" {
		t.Errorf("invalid arg value - --entry != %s", r[0])
	}
	if r[1] != "VALUE" {
		t.Errorf("invalid arg value - VALUE != %s", r[1])
	}
	if len(s.unknownFlags) != 1 {
		t.Fatalf("invalid unknown flags length - 1 != %d", len(s.unknownFlags))
	}
	if s.unknownFlags[0] != "entry" {
		t.Errorf("invalid unknown flags value - entry != %s", s.unknownFlags[0])
	}
}

func Test_Set_Parse_remaining(t *testing.T) {
	s := testSet()
	s.DefaultGroup().String("entry")
	r, err := s.Parse([]string{"--entry", "VALUE", "action"})
	if err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	if len(r) != 1 {
		t.Fatalf("invalid remaining length - 1 != %d", len(r))
	}
	if r[0] != "action" {
		t.Errorf("invalid remaining value - action != %s", r[0])
	}
}

// -vvv --entry eVALUE --mark -x xVALUE -y
func Test_Set_Parse_1(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Increment("verbosity", ShortName('v'))
	s.DefaultGroup().String("entry")
	s.DefaultGroup().Bool("mark")
	s.DefaultGroup().String("xylophone", ShortName('x'))
	s.DefaultGroup().Bool("yesterday", ShortName('y'))
	if _, err := s.Parse([]string{"-vvv", "--entry", "eVALUE", "--mark", "-x", "xVALUE", "-y"}); err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	for _, f := range s.Flags() {
		switch f.longName {
		case "verbosity":
			if f.Value().(int64) != 3 {
				t.Errorf("invalid verbosity value - 3 != %#v", f.Value())
			}
		case "entry":
			if f.Value().(string) != "eVALUE" {
				t.Errorf("invalid entry value - eVALUE != %#v", f.Value())
			}
		case "mark":
			if f.Value().(bool) != true {
				t.Errorf("invalid mark value - true != %#v", f.Value())
			}
		case "xylophone":
			if f.Value().(string) != "xVALUE" {
				t.Errorf("invalid xylophone value - xVALUE != %#v", f.Value())
			}
		case "yesterday":
			if f.Value().(bool) != true {
				t.Errorf("invalid yesterday value - true != %#v", f.Value())
			}
		}
	}
}

func Test_Set_validateFlags(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark")
	s.DefaultGroup().String("entry")
	if err := s.validateFlags(); err != nil {
		t.Errorf("unexpected validate error: %s", err)
	}
}

func Test_Set_validateFlags_single(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark", Required())
	s.DefaultGroup().String("entry")
	err := s.validateFlags()
	if err == nil {
		t.Fatalf("expected error but no error returned")
	}
	if !strings.Contains(err.Error(), "--mark") {
		t.Errorf("expected error to contain --mark but it did not - %s", err)
	}
}

func Test_Set_validateFlags_multiple(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Bool("mark", Required())
	s.DefaultGroup().String("entry", Required())
	s.DefaultGroup().Increment("verbosity")
	err := s.validateFlags()
	if err == nil {
		t.Fatalf("expected error but no error returned")
	}
	if !strings.Contains(err.Error(), "--mark") {
		t.Errorf("expected error to contain --mark but it did not - %s", err)
	}
	if !strings.Contains(err.Error(), "--entry") {
		t.Errorf("expected error to contain --entry but it did not - %s", err)
	}
}

func Test_Set_validateFlags_updated(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Bool("mark", Required())
	f.updated = true
	s.DefaultGroup().String("entry")
	err := s.validateFlags()
	if err != nil {
		t.Fatalf("error return when none was expected - %s", err)
	}
}

// Below are complex argument parse tests

// -vvyvvxxVALUE --mark --entry=EVALUE
func Test_Set_Parse_2(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Increment("verbosity", ShortName('v'))
	s.DefaultGroup().String("entry")
	s.DefaultGroup().Bool("mark")
	s.DefaultGroup().String("xylophone", ShortName('x'))
	s.DefaultGroup().Bool("yesterday", ShortName('y'))
	if _, err := s.Parse([]string{"-vvyvvxxVALUE", "--mark", "--entry=EVALUE"}); err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	for _, f := range s.Flags() {
		switch f.longName {
		case "verbosity":
			if f.Value().(int64) != 4 {
				t.Errorf("invalid verbosity value - 4 != %#v", f.Value())
			}
		case "entry":
			if f.Value().(string) != "EVALUE" {
				t.Errorf("invalid entry value - EVALUE != %#v", f.Value())
			}
		case "mark":
			if f.Value().(bool) != true {
				t.Errorf("invalid mark value - true != %#v", f.Value())
			}
		case "xylophone":
			if f.Value().(string) != "xVALUE" {
				t.Errorf("invalid xylophone value - xVALUE != %#v", f.Value())
			}
		case "yesterday":
			if f.Value().(bool) != true {
				t.Errorf("invalid yesterday value - true != %#v", f.Value())
			}
		}
	}
}

// -vvyv --xylophone xVALUE --entry=EVALUE -mv
func Test_Set_Parse_3(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Increment("verbosity", ShortName('v'))
	s.DefaultGroup().String("entry")
	s.DefaultGroup().Bool("mark", ShortName('m'))
	s.DefaultGroup().String("xylophone", ShortName('x'))
	s.DefaultGroup().Bool("yesterday", ShortName('y'))
	if _, err := s.Parse([]string{"-vvyv", "--xylophone", "xVALUE", "--entry=EVALUE", "-mv"}); err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	for _, f := range s.Flags() {
		switch f.longName {
		case "verbosity":
			if f.Value().(int64) != 4 {
				t.Errorf("invalid verbosity value - 4 != %#v", f.Value())
			}
		case "entry":
			if f.Value().(string) != "EVALUE" {
				t.Errorf("invalid entry value - EVALUE != %#v", f.Value())
			}
		case "mark":
			if f.Value().(bool) != true {
				t.Errorf("invalid mark value - true != %#v", f.Value())
			}
		case "xylophone":
			if f.Value().(string) != "xVALUE" {
				t.Errorf("invalid xylophone value - xVALUE != %#v", f.Value())
			}
		case "yesterday":
			if f.Value().(bool) != true {
				t.Errorf("invalid yesterday value - true != %#v", f.Value())
			}
		}
	}
}

// --entry 3.14 --hash ping=pong --hash=fee=fi --entry=99.9
func Test_Set_Parse_4(t *testing.T) {
	s := testSet()
	s.DefaultGroup().Array("entry", FloatType)
	s.DefaultGroup().Map("hash", StringType)
	if _, err := s.Parse([]string{"--entry", "3.14", "--hash", "ping=pong", "--hash=fee=fi", "--entry=99.9"}); err != nil {
		t.Fatalf("unexpected parse error: %s", err)
	}
	for _, f := range s.Flags() {
		switch f.longName {
		case "entry":
			v := f.Value().([]float64)
			if len(v) != 2 {
				t.Fatalf("invalid entry length - 2 != %d", len(v))
			}
			if v[0] != 3.14 {
				t.Errorf("invalid entry value - 3.14 != %#v", v)
			}
			if v[1] != 99.9 {
				t.Errorf("invalid entry value - 99.9 != %#v", v)
			}
		case "hash":
			h := f.Value().(map[string]string)
			if v, ok := h["ping"]; !ok {
				t.Errorf("invalid hash value - missing ping key")
			} else {
				if v != "pong" {
					t.Errorf("invalid hash value - pong != %#v", v)
				}
			}
			if v, ok := h["fee"]; !ok {
				t.Errorf("invalid hash value - missing fee key")
			} else {
				if v != "fi" {
					t.Errorf("invalid hash value - fi != %#v", v)
				}
			}
		}
	}
}

// TODO: add some complex usage tests which include flag modifiers
