// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flags

import (
	"strings"
	"testing"
)

func Test_HideGroupName(t *testing.T) {
	s := testSet()
	g, err := s.NewGroup("test")
	if err != nil {
		t.Fatalf("unexpected error creating group: %s", err)
	}
	if !g.showGroupName {
		t.Fatalf("invalid show group name - true != false")
	}
	HideGroupName()(g)
	if g.showGroupName {
		t.Errorf("invalid show group name - false != true")
	}
}

func Test_HideGroup(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	if g.hidden {
		t.Errorf("expected default group to not be hidden")
	}
	g.hidden = false
	HideGroup()(g)
	if !g.hidden {
		t.Errorf("invalid hidden - true != false")
	}
}

func Test_newGroup(t *testing.T) {
	s := testSet()
	g := newGroup(s, "test-group")
	if g.name != "test-group" {
		t.Errorf("invalid name - test-group != %s", g.name)
	}
	if g.set != s {
		t.Errorf("invalid set - %#v != %#v", s, g.set)
	}
	found := false
	for _, grp := range s.groups {
		if grp == g {
			found = true
			break
		}
	}
	if !found {
		t.Errorf("group not found within set")
	}
}

func Test_Group_Add(t *testing.T) {
	sSrc := testSet()
	sDst := testSet()

	f := sSrc.DefaultGroup().Bool("test-flag")
	if err := sDst.DefaultGroup().Add(f); err != nil {
		t.Fatalf("failed to add flag to group: %s", err)
	}
	if len(sDst.Flags()) != 1 {
		t.Fatalf("invalid flag length - 1 != %d", len(sDst.Flags()))
	}
	if len(sSrc.Flags()) != 0 {
		t.Errorf("invalid flag length - 0 != %d", len(sSrc.Flags()))
	}
	if sDst.Flags()[0] != f {
		t.Errorf("invalid flags - %#v != %#v", sDst.Flags()[0], f)
	}
}

func Test_Group_Name(t *testing.T) {
	s := testSet()
	g, err := s.NewGroup("name-test")
	if err != nil {
		t.Fatalf("unexpected error creating group: %s", err)
	}
	if g.Name() != "name-test" {
		t.Errorf("invalid name - name-test != %s", g.Name())
	}
}

func Test_Group_Flags(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Bool("test-bool")
	if len(s.DefaultGroup().Flags()) != 1 {
		t.Fatalf("invalid flags length - 1 != %d", len(s.DefaultGroup().Flags()))
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid flags - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
}

func Test_Group_Bool(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Bool("test-bool")
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != BooleanType {
		t.Errorf("invalid flag type - %s != %s", BooleanType.String(), f.kind.String())
	}
}

func Test_Group_BoolVar(t *testing.T) {
	s := testSet()
	var val bool
	f := s.DefaultGroup().BoolVar("test-bool", &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != BooleanType {
		t.Errorf("invalid flag type - %s != %s", BooleanType.String(), f.kind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_String(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().String("test-string")
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != StringType {
		t.Errorf("invalid flag type - %s != %s", StringType.String(), f.kind.String())
	}
}

func Test_Group_StringVar(t *testing.T) {
	s := testSet()
	var val string
	f := s.DefaultGroup().StringVar("test-string", &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != StringType {
		t.Errorf("invalid flag type - %s != %s", StringType.String(), f.kind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_Array(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Array("test-string", StringType)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != ArrayType {
		t.Errorf("invalid flag type - %s != %s", ArrayType.String(), f.kind.String())
	}
	if f.subkind != StringType {
		t.Errorf("invalid flag sub-type - %s != %s", StringType.String(), f.subkind.String())
	}
}

func Test_Group_ArrayVar(t *testing.T) {
	s := testSet()
	val := []string{}
	f := s.DefaultGroup().ArrayVar("test-string", StringType, &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != ArrayType {
		t.Errorf("invalid flag type - %s != %s", ArrayType.String(), f.kind.String())
	}
	if f.subkind != StringType {
		t.Errorf("invalid flag sub-type - %s != %s", StringType, f.subkind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_Float(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Float("test-float")
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != FloatType {
		t.Errorf("invalid flag type - %s != %s", FloatType.String(), f.kind.String())
	}
}

func Test_Group_FloatVar(t *testing.T) {
	s := testSet()
	var val float64
	f := s.DefaultGroup().FloatVar("test-string", &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != FloatType {
		t.Errorf("invalid flag type - %s != %s", FloatType.String(), f.kind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_Integer(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Integer("test-integer")
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != IntegerType {
		t.Errorf("invalid flag type - %s != %s", IntegerType.String(), f.kind.String())
	}
}

func Test_Group_IntegerVar(t *testing.T) {
	s := testSet()
	var val int64
	f := s.DefaultGroup().IntegerVar("test-string", &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != IntegerType {
		t.Errorf("invalid flag type - %s != %s", IntegerType.String(), f.kind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_Increment(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Increment("test-increment")
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != IncrementType {
		t.Errorf("invalid flag type - %s != %s", IncrementType.String(), f.kind.String())
	}
}

func Test_Group_IncrementVar(t *testing.T) {
	s := testSet()
	var val int64
	f := s.DefaultGroup().IncrementVar("test-incrmeent", &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != IncrementType {
		t.Errorf("invalid flag type - %s != %s", IncrementType.String(), f.kind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_Map(t *testing.T) {
	s := testSet()
	f := s.DefaultGroup().Map("test-string", StringType)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != MapType {
		t.Errorf("invalid flag type - %s != %s", MapType.String(), f.kind.String())
	}
	if f.subkind != StringType {
		t.Errorf("invalid flag sub-type - %s != %s", StringType.String(), f.subkind.String())
	}
}

func Test_Group_MapVar(t *testing.T) {
	s := testSet()
	val := map[string]string{}
	f := s.DefaultGroup().MapVar("test-string", StringType, &val)
	if s.Flags()[0] != f {
		t.Errorf("invalid set flag - %#v != %#v", f, s.Flags()[0])
	}
	if s.DefaultGroup().Flags()[0] != f {
		t.Errorf("invalid group flag - %#v != %#v", f, s.DefaultGroup().Flags()[0])
	}
	if f.kind != MapType {
		t.Errorf("invalid flag type - %s != %s", MapType.String(), f.kind.String())
	}
	if f.subkind != StringType {
		t.Errorf("invalid flag sub-type - %s != %s", StringType, f.subkind.String())
	}
	if !f.ptr {
		t.Errorf("invalid flag ptr - true != false")
	}
	if f.value != &val {
		t.Errorf("invalid flag value - %p != %p", &val, f.value)
	}
}

func Test_Group_Display(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Bool("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
}

func Test_Group_Display_bool(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Bool("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if !strings.Contains(d, "--[no-]") {
		t.Errorf("flag negate option missing: %s", d)
	}
}

func Test_Group_Display_integer(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Integer("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "--test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if !strings.Contains(d, "VALUE") {
		t.Errorf("VALUE option not found: %s", d)
	}
}

func Test_Group_Display_increment(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Increment("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "--test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if strings.Contains(d, "VALUE") {
		t.Errorf("VALUE option found: %s", d)
	}
}

func Test_Group_Display_float(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Float("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "--test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if !strings.Contains(d, "VALUE") {
		t.Errorf("VALUE option not found: %s", d)
	}
}

func Test_Group_Display_string(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.String("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "--test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if !strings.Contains(d, "VALUE") {
		t.Errorf("VALUE option not found: %s", d)
	}
}

func Test_Group_Display_array(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Array("test-flag", StringType)
	d := g.Display(0)
	if !strings.Contains(d, "--test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if !strings.Contains(d, "VALUE") {
		t.Errorf("VALUE option not found: %s", d)
	}
}

func Test_Group_Display_map(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Map("test-flag", StringType)
	d := g.Display(0)
	if !strings.Contains(d, "--test-flag") {
		t.Errorf("flag 'test-flag' not found: %s", d)
	}
	if !strings.Contains(d, "VALUE") {
		t.Errorf("VALUE option not found: %s", d)
	}
}

func Test_Group_Display_hidden_flag(t *testing.T) {
	s := testSet()
	g := s.DefaultGroup()
	g.Bool("visible-option")
	g.Bool("hidden-option", Hidden())
	d := g.Display(0)
	if !strings.Contains(d, "visible-option") {
		t.Errorf("visible flag 'visible-option' not found: %s", d)
	}
	if strings.Contains(d, "hidden-option") {
		t.Errorf("hidden flag 'hidden-option' found: %s", d)
	}
}

func Test_Group_Display_group_name(t *testing.T) {
	s := testSet()
	g, err := s.NewGroup("Test Group")
	if err != nil {
		t.Fatalf("unexpected error creating group: %s", err)
	}
	g.Bool("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "test-flag") {
		t.Errorf("flag not found: %s", d)
	}
	if !strings.Contains(d, "Test Group") {
		t.Errorf("group name not found: %s", d)
	}
}

func Test_Group_Display_group_name_hidden(t *testing.T) {
	s := testSet()
	g, err := s.NewGroup("Test Group", HideGroupName())
	if err != nil {
		t.Fatalf("unexpected error creating group: %s", err)
	}
	g.Bool("test-flag")
	d := g.Display(0)
	if !strings.Contains(d, "test-flag") {
		t.Errorf("flag not found: %s", d)
	}
	if strings.Contains(d, "Test Group") {
		t.Errorf("group name found: %s", d)
	}
}

func Test_Group_Display_hidden(t *testing.T) {
	s := testSet()
	g, err := s.NewGroup("Test Group", HideGroup())
	if err != nil {
		t.Fatalf("unexpected error creating group: %s", err)
	}
	g.Bool("test-flag")
	d := g.Display(0)
	if d != "" {
		t.Errorf("encountered output for hidden group: %s", d)
	}
}
