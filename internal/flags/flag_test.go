// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flags

import (
	"errors"
	"os"
	"testing"
)

func testSet() *Set {
	return NewSet("testing-set")
}

func testGroup() *Group {
	return testSet().DefaultGroup()
}

func testFlag(g *Group) *Flag {
	return newFlag("test-flag", StringType, g)
}

func Test_newFlag(t *testing.T) {
	g := testGroup()
	f := newFlag("my-flag", StringType, g)
	if f.longName != "my-flag" {
		t.Errorf("invalid name - my-flag != %s", f.longName)
	}
	if f.kind != StringType {
		t.Errorf("invalid kind - String != %s", f.kind.String())
	}
	if f.called {
		t.Errorf("invalid called - true != false")
	}
	if f.group != g {
		t.Errorf("invalid group - %v != %v", g, f.group)
	}
	if f.envVar != "" {
		t.Errorf("invalid envVar - \"\" != %s", f.envVar)
	}
	if f.hidden {
		t.Errorf("invalid hidden - true != false")
	}
	if f.ptr {
		t.Errorf("invalid ptr - true != false")
	}
	if f.required {
		t.Errorf("invalid required - true != false")
	}
	if f.shortName != 0 {
		t.Errorf("invalid shortName - 0 != %d", f.shortName)
	}
	if f.subkind != UnsetType {
		t.Errorf("invalid subkind - %s != %s", UnsetType.String(), f.subkind.String())
	}
	if f.updated {
		t.Errorf("invalid updated - true != false")
	}
	if f.value != nil {
		t.Errorf("invalid value - nil != %v", f.value)
	}
}

func Test_Alias(t *testing.T) {
	f := testFlag(testGroup())
	aliases := []string{"your-flag", "their-flag"}
	fn := Alias(aliases...)
	fn(f)
	if len(f.aliases) != len(aliases) {
		t.Errorf("invalid aliases - %v != %v", aliases, f.aliases)
	}
	for i, a := range aliases {
		if a != f.aliases[i] {
			t.Errorf("invalid alias @ %d - %v != %v", i, a, f.aliases[i])
		}
	}
}

func Test_Required(t *testing.T) {
	f := testFlag(testGroup())
	f.required = false
	fn := Required()
	fn(f)
	if !f.required {
		t.Errorf("invalid required - false != true")
	}
}

func Test_Optional(t *testing.T) {
	f := testFlag(testGroup())
	f.required = true
	fn := Optional()
	fn(f)
	if f.required {
		t.Errorf("invalid required - true != false")
	}
}

func Test_Hidden(t *testing.T) {
	f := testFlag(testGroup())
	f.hidden = false
	fn := Hidden()
	fn(f)
	if !f.hidden {
		t.Errorf("invalid hidden - false != true")
	}
}

func Test_DefaultValue(t *testing.T) {
	f := testFlag(testGroup())
	v := "my default value"
	fn := DefaultValue(v)
	fn(f)
	if f.defaultValue != v {
		t.Errorf("invalid default value - %s != %s", v, f.defaultValue)
	}
}

func Test_DefaultValue_invalid_type(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("panic expected but did not occur")
		}
	}()
	f := testFlag(testGroup())
	f.kind = IntegerType
	v := "my default value"
	fn := DefaultValue(v)
	fn(f)
}

func Test_EnvVar(t *testing.T) {
	f := testFlag(testGroup())
	v := "MY_VAR"
	fn := EnvVar(v)
	fn(f)
	if f.envVar != v {
		t.Errorf("invalid env var - %s != %s", v, f.envVar)
	}
}

func Test_ShortName(t *testing.T) {
	f := testFlag(testGroup())
	fn := ShortName('t')
	fn(f)
	if f.shortName != 't' {
		t.Fatalf("invalid shortName - t != %c", f.shortName)
	}
}

func Test_Subtype(t *testing.T) {
	f := testFlag(testGroup())
	fn := SetSubtype(IntegerType)
	fn(f)
	if f.subkind != IntegerType {
		t.Errorf("invalid subkind - %s != %s", IntegerType.String(), f.subkind.String())
	}
}

func Test_AddProcessor(t *testing.T) {
	f := testFlag(testGroup())
	AddProcessor(func(f *Flag, v interface{}) (interface{}, error) {
		return v.(string) + "-modified", nil
	})(f)
	if err := f.setValue("test-value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value() != "test-value-modified" {
		t.Errorf("invalid value - test-value-modified != %#v", f.Value())
	}
}

func Test_AddProcessor_error(t *testing.T) {
	f := testFlag(testGroup())
	AddProcessor(func(f *Flag, v interface{}) (interface{}, error) {
		return nil, errors.New("processor error")
	})(f)
	if err := f.setValue("test-value"); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_AddCallback(t *testing.T) {
	f := testFlag(testGroup())
	mark := false
	AddCallback(func(f *Flag) error {
		mark = true
		return nil
	})(f)
	if err := f.setValue("test-value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if !mark {
		t.Errorf("callback did not set mark")
	}
}

func Test_AddCallback_error(t *testing.T) {
	f := testFlag(testGroup())
	AddCallback(func(f *Flag) error {
		return errors.New("callback error")
	})(f)
	if err := f.setValue("test-value"); err == nil {
		t.Errorf("expected error but no error returned")
	}
}

func Test_customVar(t *testing.T) {
	var v string
	f := testFlag(testGroup())
	fn := customVar(&v)
	fn(f)
	tv := "custom-test-value"
	f.setValue(tv)
	if f.Value() != tv {
		t.Errorf("invalid value - %s != %s", tv, f.Value())
	}
}

func Test_Flag_Aliases(t *testing.T) {
	f := testFlag(testGroup())
	if len(f.Aliases()) != 0 {
		t.Errorf("invalid Aliases length - 0 != %d", len(f.Aliases()))
	}
	f.aliases = []string{"my-alias"}
	if len(f.Aliases()) != 1 {
		t.Fatalf("invalid Aliases length - 1 != %d", len(f.Aliases()))
	}
	if f.aliases[0] != "my-alias" {
		t.Errorf("invalid Aliases entry - my-aliase != %s", f.aliases[0])
	}
}

func Test_Flag_Called(t *testing.T) {
	f := testFlag(testGroup())
	if f.Called() {
		t.Errorf("invalid Called - true != false")
	}
	f.called = true
	if !f.Called() {
		t.Errorf("invalid Called - false != true")
	}
}

func Test_Flag_DefaultValue(t *testing.T) {
	f := testFlag(testGroup())
	val := "test-default-value"
	f.defaultValue = val
	if f.DefaultValue() != val {
		t.Errorf("invalid DefaultValue - %s != %s", val, f.DefaultValue())
	}
}

func Test_Flag_EnvVar(t *testing.T) {
	f := testFlag(testGroup())
	val := "TEST_ENV_VAR"
	f.envVar = val
	if f.EnvVar() != val {
		t.Errorf("invalid EnvVar - %s != %s", val, f.EnvVar())
	}
}

func Test_Flag_Group(t *testing.T) {
	g := testGroup()
	f := testFlag(g)
	if f.Group() != g {
		t.Errorf("invalid Group - %#v != %#v", g, f.Group())
	}
}

func Test_Flag_Hidden(t *testing.T) {
	f := testFlag(testGroup())
	if f.Hidden() {
		t.Errorf("invalid Hidden - true != false")
	}
	f.hidden = true
	if !f.Hidden() {
		t.Errorf("invalid Hidden - false != true")
	}
}

func Test_Flag_LongName(t *testing.T) {
	f := testFlag(testGroup())
	if f.LongName() != f.longName {
		t.Errorf("invalid LongName - %s != %s", f.longName, f.LongName())
	}
}

func Test_Flag_Required(t *testing.T) {
	f := testFlag(testGroup())
	if f.Required() {
		t.Errorf("invalid Required - true != false")
	}
	f.required = true
	if !f.Required() {
		t.Errorf("invalid Required - false != true")
	}
}

func Test_Flag_ShortName(t *testing.T) {
	f := testFlag(testGroup())
	if f.ShortName() != 0 {
		t.Errorf("invalid ShortName - 0 != %d", f.ShortName())
	}
	f.shortName = 't'
	if f.ShortName() != 't' {
		t.Errorf("invalid ShortName - t != %c", f.ShortName())
	}
}

func Test_Flag_Updated(t *testing.T) {
	f := testFlag(testGroup())
	if f.Updated() {
		t.Errorf("invalid Updated - true != false")
	}
	f.updated = true
	if !f.Updated() {
		t.Errorf("invalid Updated - false != true")
	}
}

func Test_Flag_Value(t *testing.T) {
	f := testFlag(testGroup())
	val := "test-val"
	f.value = val
	if f.Value() != val {
		t.Errorf("invalid Value - %s != %s", val, f.Value())
	}
}

func Test_Flag_Value_Boolean(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = BooleanType
	f.value = true
	if f.Value() != true {
		t.Errorf("invalid Value - false != true")
	}
	f.value = false
	if f.Value() != false {
		t.Errorf("invalid Value - true != false")
	}
}

func Test_Flag_Value_Float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = FloatType
	f.value = 3.4
	if f.Value() != 3.4 {
		t.Errorf("invalid Value - 3.4 != %f", f.Value())
	}
}

func Test_Flag_Value_String(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = IntegerType
	f.value = 10
	if f.Value() != 10 {
		t.Errorf("invalid Value - 10 != %d", f.Value())
	}
}

func Test_Flag_markCalled(t *testing.T) {
	f := testFlag(testGroup())
	f.markCalled("test-flag")
	if f.matchedName != "test-flag" {
		t.Errorf("invalid matchedName - test-flag != %s", f.matchedName)
	}
	if !f.updated {
		t.Errorf("invalid updated - true != false")
	}
	if !f.called {
		t.Errorf("invalid called - true != false")
	}
}

func Test_Flag_markCalled_invalid(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("panic expected but did not occur")
		}
	}()
	f := testFlag(testGroup())
	f.markCalled("invalid-name")
}

func Test_Flag_markCalled_short(t *testing.T) {
	f := testFlag(testGroup())
	f.shortName = 't'
	f.markCalled("t")
	if !f.called {
		t.Errorf("invalid called - true != false")
	}
}

func Test_Flag_markCalled_alias(t *testing.T) {
	f := testFlag(testGroup())
	f.aliases = []string{"otherflag", "real-name"}
	f.markCalled("real-name")
	if !f.called {
		t.Errorf("invalid called - true != false")
	}
}

func Test_Flag_init(t *testing.T) {
	f := testFlag(testGroup())
	err := f.init()
	if err != nil {
		t.Errorf("unexpected error: %s", err)
	}
	if f.value != "" {
		t.Errorf("invalid value - empty string != %#v", f.value)
	}
}

func Test_Flag_init_used(t *testing.T) {
	f := testFlag(testGroup())
	f.updated = true
	err := f.init()
	if err == nil {
		t.Error("expected error but did not occur")
	}
}

func Test_Flag_init_array_bool(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = BooleanType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.([]bool); !ok {
		t.Errorf("invalid value - []bool != %T", f.value)
	}
}

func Test_Flag_init_array_float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = FloatType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.([]float64); !ok {
		t.Errorf("invalid value - []float64 != %T", f.value)
	}
}

func Test_Flag_init_array_integer(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = IntegerType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.([]int64); !ok {
		t.Errorf("invalid value - []int64 != %T", f.value)
	}
}

func Test_Flag_init_array_string(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = StringType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.([]string); !ok {
		t.Errorf("invalid value - []string != %T", f.value)
	}
}

func Test_Flag_init_boolean(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = BooleanType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(bool); !ok {
		t.Errorf("invalid value - bool != %T", f.value)
	}
}

func Test_Flag_init_float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = FloatType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(float64); !ok {
		t.Errorf("invalid value - float64 != %T", f.value)
	}
}

func Test_Flag_init_increment(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = IncrementType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(int64); !ok {
		t.Errorf("invalid value - int64 != %T", f.value)
	}
}

func Test_Flag_init_integer(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = IntegerType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(int64); !ok {
		t.Errorf("invalid value - int64 != %T", f.value)
	}
}

func Test_Flag_init_map_bool(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = BooleanType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(map[string]bool); !ok {
		t.Errorf("invalid value - map[string]bool != %T", f.value)
	}
}

func Test_Flag_init_map_float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = FloatType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(map[string]float64); !ok {
		t.Errorf("invalid value - map[string]float64 != %T", f.value)
	}
}

func Test_Flag_init_map_integer(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = IntegerType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(map[string]int64); !ok {
		t.Errorf("invalid value - map[string]int64 != %T", f.value)
	}
}

func Test_Flag_init_map_string(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = StringType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(map[string]string); !ok {
		t.Errorf("invalid value - map[string]string != %T", f.value)
	}
}

func Test_Flag_init_string(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = StringType
	err := f.init()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if _, ok := f.value.(string); !ok {
		t.Errorf("invalid value - string != %T", f.value)
	}
}

func Test_Flag_init_map_invalid(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("panic expected but did not occur")
		}
	}()
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = ArrayType
	f.init()
}

func Test_Flag_init_array_invalid(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Errorf("panic expected but did not occur")
		}
	}()
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = MapType
	f.init()
}

func Test_Flag_init_envVar(t *testing.T) {
	defer func() {
		os.Setenv("FLAG_ENV_TEST", "")
	}()
	f := testFlag(testGroup())
	f.envVar = "FLAG_ENV_TEST"
	val := "env-test-value"
	if err := os.Setenv("FLAG_ENV_TEST", val); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.init(); err != nil {
		t.Errorf("unexpected error: %s", err)
	}
	if f.value != val {
		t.Errorf("invalid value - %s != %s", val, f.value)
	}
}

func Test_Flag_setValue_array_bool(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = BooleanType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("true"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]bool)
	if !ok {
		t.Errorf("invalid value type - []bool != %T", f.Value())
	}
	if !v[0] {
		t.Errorf("invalid array value - true != false")
	}
}

func Test_Flag_setValue_array_bool_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = BooleanType
	val := []bool{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("true"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]bool)
	if !ok {
		t.Errorf("invalid value type - []bool != %T", f.Value())
	}
	if !v[0] {
		t.Errorf("invalid array value - true != false")
	}
	if !val[0] {
		t.Errorf("invalid array value - true != false")
	}
}

func Test_Flag_setValue_array_bool_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = BooleanType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("true"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("false"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]bool)
	if !ok {
		t.Errorf("invalid value type - []bool != %T", f.Value())
	}
	if !v[0] {
		t.Errorf("invalid array value - true != false")
	}
	if v[1] {
		t.Errorf("invalid array value - false != true")
	}
}

func Test_Flag_setValue_array_bool_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = BooleanType
	val := []bool{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("true"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("false"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]bool)
	if !ok {
		t.Errorf("invalid value type - []bool != %T", f.Value())
	}
	if !v[0] {
		t.Errorf("invalid array value - true != false")
	}
	if v[1] {
		t.Errorf("invalid array value - false != true")
	}
	if !val[0] {
		t.Errorf("invalid array value - true != false")
	}
	if val[1] {
		t.Errorf("invalid array value - false != true")
	}
}

func Test_Flag_setValue_array_float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = FloatType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("4.2"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]float64)
	if !ok {
		t.Errorf("invalid value type - []float64 != %T", f.Value())
	}
	if v[0] != 4.2 {
		t.Errorf("invalid array value - 4.2 != %#v", v[0])
	}
}

func Test_Flag_setValue_array_float_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = FloatType
	val := []float64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("4.2"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]float64)
	if !ok {
		t.Errorf("invalid value type - []float64 != %T", f.Value())
	}
	if v[0] != 4.2 {
		t.Errorf("invalid array value - 4.2 != %#v", v[0])
	}
	if val[0] != 4.2 {
		t.Errorf("invalid array value - 4.2 != %#v", val[0])
	}
}

func Test_Flag_setValue_array_float_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = FloatType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("4.2"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("10.5"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]float64)
	if !ok {
		t.Errorf("invalid value type - []float64 != %T", f.Value())
	}
	if v[0] != 4.2 {
		t.Errorf("invalid array value - 4.2 != %#v", v[0])
	}
	if v[1] != 10.5 {
		t.Errorf("invalid array value - 10.5 != %#v", v[1])
	}
}

func Test_Flag_setValue_array_float_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = FloatType
	val := []float64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("4.2"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("10.5"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]float64)
	if !ok {
		t.Errorf("invalid value type - []float64 != %T", f.Value())
	}
	if v[0] != 4.2 {
		t.Errorf("invalid array value - 4.2 != %#v", v[0])
	}
	if v[1] != 10.5 {
		t.Errorf("invalid array value - 10.5 != %#v", v[1])
	}
	if val[0] != 4.2 {
		t.Errorf("invalid array value - 4.2 != %#v", val[0])
	}
	if val[1] != 10.5 {
		t.Errorf("invalid array value - 10.5 != %#v", val[1])
	}
}

func Test_Flag_setValue_array_integer(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = IntegerType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("100"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]int64)
	if !ok {
		t.Errorf("invalid value type - []int64 != %T", f.Value())
	}
	if v[0] != 100 {
		t.Errorf("invalid array value - 100 != %#v", v[0])
	}
}

func Test_Flag_setValue_array_integer_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = IntegerType
	val := []int64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("100"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]int64)
	if !ok {
		t.Errorf("invalid value type - []int64 != %T", f.Value())
	}
	if v[0] != 100 {
		t.Errorf("invalid array value - 100 != %#v", v[0])
	}
	if val[0] != 100 {
		t.Errorf("invalid array value - 100 != %#v", val[0])
	}
}

func Test_Flag_setValue_array_integer_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = IntegerType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("100"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("-22"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]int64)
	if !ok {
		t.Errorf("invalid value type - []int64 != %T", f.Value())
	}
	if v[0] != 100 {
		t.Errorf("invalid array value - 100 != %#v", v[0])
	}
	if v[1] != -22 {
		t.Errorf("invalid array value - -22 != %#v", v[1])
	}
}

func Test_Flag_setValue_array_integer_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = IntegerType
	val := []int64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("100"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("-22"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]int64)
	if !ok {
		t.Errorf("invalid value type - []int64 != %T", f.Value())
	}
	if v[0] != 100 {
		t.Errorf("invalid array value - 100 != %#v", v[0])
	}
	if v[1] != -22 {
		t.Errorf("invalid array value - -22 != %#v", v[1])
	}
	if val[0] != 100 {
		t.Errorf("invalid array value - 100 != %#v", val[0])
	}
	if val[1] != -22 {
		t.Errorf("invalid array value - -22 != %#v", val[1])
	}
}

func Test_Flag_setValue_array_string(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = StringType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("test value"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]string)
	if !ok {
		t.Errorf("invalid value type - []string != %T", f.Value())
	}
	if v[0] != "test value" {
		t.Errorf("invalid array value - test value != %#v", v[0])
	}
}

func Test_Flag_setValue_array_string_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = StringType
	val := []string{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("test value"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]string)
	if !ok {
		t.Errorf("invalid value type - []string != %T", f.Value())
	}
	if v[0] != "test value" {
		t.Errorf("invalid array value - test value != %#v", v[0])
	}
	if val[0] != "test value" {
		t.Errorf("invalid array value - test value != %#v", val[0])
	}
}

func Test_Flag_setValue_array_string_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = StringType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("test value"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("second test value"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]string)
	if !ok {
		t.Errorf("invalid value type - []string != %T", f.Value())
	}
	if v[0] != "test value" {
		t.Errorf("invalid array value - test value != %#v", v[0])
	}
	if v[1] != "second test value" {
		t.Errorf("invalid array value - second test value != %#v", v[1])
	}
}

func Test_Flag_setValue_array_string_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = ArrayType
	f.subkind = StringType
	val := []string{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("test value"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	if err := f.setValue("second test value"); err != nil {
		t.Errorf("failed to set value: %s", err)
	}
	v, ok := f.Value().([]string)
	if !ok {
		t.Errorf("invalid value type - []string != %T", f.Value())
	}
	if v[0] != "test value" {
		t.Errorf("invalid array value - test value != %#v", v[0])
	}
	if v[1] != "second test value" {
		t.Errorf("invalid array value - second test value != %#v", v[1])
	}
	if val[0] != "test value" {
		t.Errorf("invalid array value - test value != %#v", val[0])
	}
	if val[1] != "second test value" {
		t.Errorf("invalid array value - second test value != %#v", val[1])
	}
}

func Test_Flag_setValue_map_bool(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = BooleanType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=true"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]bool)
	if !ok {
		t.Fatalf("invalid value type - map[string]bool != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if !v["ack"] {
		t.Errorf("invalid map value - true != false")
	}
}

func Test_Flag_setValue_map_bool_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = BooleanType
	val := map[string]bool{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=true"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]bool)
	if !ok {
		t.Fatalf("invalid value type - map[string]bool != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if !v["ack"] {
		t.Errorf("invalid map value - true != false")
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if !val["ack"] {
		t.Errorf("invalid map value - true != false")
	}
}

func Test_Flag_setValue_map_bool_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = BooleanType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=true"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=false"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]bool)
	if !ok {
		t.Fatalf("invalid value type - map[string]bool != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if !v["ack"] {
		t.Errorf("invalid map value - true != false")
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] {
		t.Errorf("invalid map value - false != true")
	}
}

func Test_Flag_setValue_map_bool_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = BooleanType
	val := map[string]bool{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=true"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=false"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]bool)
	if !ok {
		t.Fatalf("invalid value type - map[string]bool != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if !v["ack"] {
		t.Errorf("invalid map value - true != false")
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] {
		t.Errorf("invalid map value - false != true")
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if !val["ack"] {
		t.Errorf("invalid map value - true != false")
	}
	if _, ok := val["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["bar"] {
		t.Errorf("invalid map value - false != true")
	}
}

func Test_Flag_setValue_map_float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = FloatType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2.2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]float64)
	if !ok {
		t.Fatalf("invalid value type - map[string]float64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2.2 {
		t.Errorf("invalid map value - 2.2 != %#v", v["ack"])
	}
}

func Test_Flag_setValue_map_float_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = FloatType
	val := map[string]float64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2.2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]float64)
	if !ok {
		t.Fatalf("invalid value type - map[string]float64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2.2 {
		t.Errorf("invalid map value - 2.2 != %#v", v["ack"])
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["ack"] != 2.2 {
		t.Errorf("invalid map value - 2.2 != %#v", val["ack"])
	}
}

func Test_Flag_setValue_map_float_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = FloatType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2.2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=10"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]float64)
	if !ok {
		t.Fatalf("invalid value type - map[string]float64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2.2 {
		t.Errorf("invalid map value - 2.2 != %#v", v["ack"])
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] != 10 {
		t.Errorf("invalid map value - 10 != %#v", v["bar"])
	}
}

func Test_Flag_setValue_map_float_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = FloatType
	val := map[string]float64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2.2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=10"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]float64)
	if !ok {
		t.Fatalf("invalid value type - map[string]float64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2.2 {
		t.Errorf("invalid map value - 2.2 != %#v", v["ack"])
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] != 10 {
		t.Errorf("invalid map value - 10 != %#v", v["bar"])
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["ack"] != 2.2 {
		t.Errorf("invalid map value - 2.2 != %#v", val["ack"])
	}
	if _, ok := val["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["bar"] != 10 {
		t.Errorf("invalid map value - 10 != %#v", val["bar"])
	}
}

func Test_Flag_setValue_map_integer(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = IntegerType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]int64)
	if !ok {
		t.Fatalf("invalid value type - map[string]int64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2 {
		t.Errorf("invalid map value - 2 != %#v", v["ack"])
	}
}

func Test_Flag_setValue_map_integer_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = IntegerType
	val := map[string]int64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]int64)
	if !ok {
		t.Fatalf("invalid value type - map[string]int64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2 {
		t.Errorf("invalid map value - 2 != %#v", v["ack"])
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["ack"] != 2 {
		t.Errorf("invalid map value - 2 != %#v", val["ack"])
	}
}

func Test_Flag_setValue_map_integer_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = IntegerType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=10"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]int64)
	if !ok {
		t.Fatalf("invalid value type - map[string]int64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2 {
		t.Errorf("invalid map value - 2 != %#v", v["ack"])
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] != 10 {
		t.Errorf("invalid map value - 10 != %#v", v["bar"])
	}
}

func Test_Flag_setValue_map_integer_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = IntegerType
	val := map[string]int64{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=10"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]int64)
	if !ok {
		t.Fatalf("invalid value type - map[string]float64 != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != 2 {
		t.Errorf("invalid map value - 2 != %#v", v["ack"])
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] != 10 {
		t.Errorf("invalid map value - 10 != %#v", v["bar"])
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["ack"] != 2 {
		t.Errorf("invalid map value - 2 != %#v", val["ack"])
	}
	if _, ok := val["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["bar"] != 10 {
		t.Errorf("invalid map value - 10 != %#v", val["bar"])
	}
}

func Test_Flag_setValue_map_string(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = StringType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=test value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]string)
	if !ok {
		t.Fatalf("invalid value type - map[string]string != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != "test value" {
		t.Errorf("invalid map value - test value != %#v", v["ack"])
	}
}

func Test_Flag_setValue_map_string_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = StringType
	val := map[string]string{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=test value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]string)
	if !ok {
		t.Fatalf("invalid value type - map[string]string != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != "test value" {
		t.Errorf("invalid map value - test value != %#v", v["ack"])
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["ack"] != "test value" {
		t.Errorf("invalid map value - test value != %#v", val["ack"])
	}
}

func Test_Flag_setValue_map_string_multi(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = StringType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=test value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=another thing"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]string)
	if !ok {
		t.Fatalf("invalid value type - map[string]string != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != "test value" {
		t.Errorf("invalid map value - test value != %#v", v["ack"])
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] != "another thing" {
		t.Errorf("invalid map value - another thing != %#v", v["bar"])
	}
}

func Test_Flag_setValue_map_string_multi_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = MapType
	f.subkind = StringType
	val := map[string]string{}
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("ack=test value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if err := f.setValue("bar=another thing"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	v, ok := f.Value().(map[string]string)
	if !ok {
		t.Fatalf("invalid value type - map[string]string != %T", f.Value())
	}
	if _, ok := v["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["ack"] != "test value" {
		t.Errorf("invalid map value - test value != %#v", v["ack"])
	}
	if _, ok := v["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if v["bar"] != "another thing" {
		t.Errorf("invalid map value - another thing != %#v", v["bar"])
	}
	if _, ok := val["ack"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["ack"] != "test value" {
		t.Errorf("invalid map value - test value != %#v", val["ack"])
	}
	if _, ok := val["bar"]; !ok {
		t.Fatalf("invalid map value - key does not exist")
	}
	if val["bar"] != "another thing" {
		t.Errorf("invalid map value - another thing != %#v", val["bar"])
	}
}

func Test_Flag_setValue_bool(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = BooleanType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("false"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(bool) {
		t.Errorf("invalid value - false != true")
	}
	if err := f.setValue("true"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if !f.Value().(bool) {
		t.Errorf("invalid value - true != false")
	}
}

func Test_Flag_setValue_bool_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = BooleanType
	var val bool
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("false"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(bool) {
		t.Errorf("invalid value - false != true")
	}
	if val {
		t.Errorf("invalid value - false != true")
	}
	if err := f.setValue("true"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if !f.Value().(bool) {
		t.Errorf("invalid value - true != false")
	}
	if !val {
		t.Errorf("invalid value - false != true")
	}
}

func Test_Flag_setValue_float(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = FloatType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("2.2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(float64) != 2.2 {
		t.Errorf("invalid value - 2.2 != %#v", f.Value())
	}
}

func Test_Flag_setValue_float_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = FloatType
	var val float64
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("2.2"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(float64) != 2.2 {
		t.Errorf("invalid value - 2.2 != %#v", f.Value())
	}
	if val != 2.2 {
		t.Errorf("invalid value - 2.2 != %#v", val)
	}
}

func Test_Flag_setValue_increment(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = IncrementType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("1"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(int64) != 1 {
		t.Errorf("invalid value - 1 != %#v", f.Value())
	}
	if err := f.setValue("1"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(int64) != 2 {
		t.Errorf("invalid value - 2 != %#v", f.Value())
	}
}

func Test_Flag_setValue_increment_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = IncrementType
	var val int64
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("1"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(int64) != 1 {
		t.Errorf("invalid value - 1 != %#v", f.Value())
	}
	if val != 1 {
		t.Errorf("invalid value - 1 != %#v", val)
	}
	if err := f.setValue("1"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(int64) != 2 {
		t.Errorf("invalid value - 2 != %#v", f.Value())
	}
	if val != 2 {
		t.Errorf("invalid value - 2 != %#v", val)
	}
}

func Test_Flag_setValue_string(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = StringType
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("test-value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(string) != "test-value" {
		t.Errorf("invalid value - test-value != %#v", f.Value())
	}
}

func Test_Flag_setValue_string_ptr(t *testing.T) {
	f := testFlag(testGroup())
	f.kind = StringType
	var val string
	customVar(&val)(f)
	if err := f.init(); err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if err := f.setValue("test-value"); err != nil {
		t.Fatalf("failed to set value: %s", err)
	}
	if f.Value().(string) != "test-value" {
		t.Errorf("invalid value - test-value != %#v", f.Value())
	}
	if val != "test-value" {
		t.Errorf("invalid value - test-value != %#v", val)
	}
}
