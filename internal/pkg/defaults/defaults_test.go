// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package defaults

import (
	"reflect"
	"testing"
	"time"

	"github.com/hashicorp/vagrant/internal/pkg/defaults/internal/fixture"
)

type (
	MyInt     int
	MyInt8    int8
	MyInt16   int16
	MyInt32   int32
	MyInt64   int64
	MyUint    uint
	MyUint8   uint8
	MyUint16  uint16
	MyUint32  uint32
	MyUint64  uint64
	MyUintptr uintptr
	MyFloat32 float32
	MyFloat64 float64
	MyBool    bool
	MyString  string
	MyMap     map[string]int
	MySlice   []int
)

type Sample struct {
	Int       int           `default:"1"`
	Int8      int8          `default:"8"`
	Int16     int16         `default:"16"`
	Int32     int32         `default:"32"`
	Int64     int64         `default:"64"`
	Uint      uint          `default:"1"`
	Uint8     uint8         `default:"8"`
	Uint16    uint16        `default:"16"`
	Uint32    uint32        `default:"32"`
	Uint64    uint64        `default:"64"`
	Uintptr   uintptr       `default:"1"`
	Float32   float32       `default:"1.32"`
	Float64   float64       `default:"1.64"`
	BoolTrue  bool          `default:"true"`
	BoolFalse bool          `default:"false"`
	String    string        `default:"hello"`
	Duration  time.Duration `default:"10s"`

	BoolPtrUnset    *bool `default:"true"`
	BoolPtrSetFalse *bool `default:"true"`
	BoolPtrSetTrue  *bool `default:"true"`

	IntOct    int    `default:"0o1"`
	Int8Oct   int8   `default:"0o10"`
	Int16Oct  int16  `default:"0o20"`
	Int32Oct  int32  `default:"0o40"`
	Int64Oct  int64  `default:"0o100"`
	UintOct   uint   `default:"0o1"`
	Uint8Oct  uint8  `default:"0o10"`
	Uint16Oct uint16 `default:"0o20"`
	Uint32Oct uint32 `default:"0o40"`
	Uint64Oct uint64 `default:"0o100"`

	IntHex    int    `default:"0x1"`
	Int8Hex   int8   `default:"0x8"`
	Int16Hex  int16  `default:"0x10"`
	Int32Hex  int32  `default:"0x20"`
	Int64Hex  int64  `default:"0x40"`
	UintHex   uint   `default:"0x1"`
	Uint8Hex  uint8  `default:"0x8"`
	Uint16Hex uint16 `default:"0x10"`
	Uint32Hex uint32 `default:"0x20"`
	Uint64Hex uint64 `default:"0x40"`

	IntBin    int    `default:"0b1"`
	Int8Bin   int8   `default:"0b1000"`
	Int16Bin  int16  `default:"0b10000"`
	Int32Bin  int32  `default:"0b100000"`
	Int64Bin  int64  `default:"0b1000000"`
	UintBin   uint   `default:"0b1"`
	Uint8Bin  uint8  `default:"0b1000"`
	Uint16Bin uint16 `default:"0b10000"`
	Uint32Bin uint32 `default:"0b100000"`
	Uint64Bin uint64 `default:"0b1000000"`

	Struct    Struct         `default:"{}"`
	StructPtr *Struct        `default:"{}"`
	Map       map[string]int `default:"{}"`
	Slice     []string       `default:"[]"`

	MyInt       MyInt     `default:"1"`
	MyInt8      MyInt8    `default:"8"`
	MyInt16     MyInt16   `default:"16"`
	MyInt32     MyInt32   `default:"32"`
	MyInt64     MyInt64   `default:"64"`
	MyUint      MyUint    `default:"1"`
	MyUint8     MyUint8   `default:"8"`
	MyUint16    MyUint16  `default:"16"`
	MyUint32    MyUint32  `default:"32"`
	MyUint64    MyUint64  `default:"64"`
	MyUintptr   MyUintptr `default:"1"`
	MyFloat32   MyFloat32 `default:"1.32"`
	MyFloat64   MyFloat64 `default:"1.64"`
	MyBoolTrue  MyBool    `default:"true"`
	MyBoolFalse MyBool    `default:"false"`
	MyString    MyString  `default:"hello"`
	MyMap       MyMap     `default:"{}"`
	MySlice     MySlice   `default:"[]"`

	StructWithJSON    Struct         `default:"{\"Foo\": 123}"`
	StructPtrWithJSON *Struct        `default:"{\"Foo\": 123}"`
	MapWithJSON       map[string]int `default:"{\"foo\": 123}"`
	SliceWithJSON     []string       `default:"[\"foo\"]"`

	Empty string `default:""`

	NoDefault       *string `default:"-"`
	NoDefaultStruct Struct  `default:"-"`

	MapWithNoTag                map[string]int
	SliceWithNoTag              []string
	StructPtrWithNoTag          *Struct
	StructWithNoTag             Struct
	DeepSliceOfStructsWithNoTag [][][]Struct

	NonInitialString    string  `default:"foo"`
	NonInitialSlice     []int   `default:"[123]"`
	NonInitialStruct    Struct  `default:"{}"`
	NonInitialStructPtr *Struct `default:"{}"`
}

type Struct struct {
	Emmbeded `default:"{}"`

	Foo         int
	Bar         int
	WithDefault string `default:"foo"`
}

func (s *Struct) SetDefaults() {
	s.Bar = 456
}

type Emmbeded struct {
	Int int `default:"1"`
}

func TestInit(t *testing.T) {
	trueVal := true
	falseVal := false

	sample := &Sample{
		BoolPtrSetTrue:              &trueVal,
		BoolPtrSetFalse:             &falseVal,
		NonInitialString:            "string",
		NonInitialSlice:             []int{1, 2, 3},
		NonInitialStruct:            Struct{Foo: 123},
		NonInitialStructPtr:         &Struct{Foo: 123},
		DeepSliceOfStructsWithNoTag: [][][]Struct{{{{Foo: 123}}}},
	}

	if err := Set(sample); err != nil {
		t.Fatalf("it should not return an error: %v", err)
	}

	nonPtrVal := 1

	if err := Set(nonPtrVal); err == nil {
		t.Fatalf("it should return an error when used for a non-pointer type")
	}
	if err := Set(&nonPtrVal); err == nil {
		t.Fatalf("it should return an error when used for a non-pointer type")
	}

	Set(&fixture.Sample{}) // should not panic

	t.Run("bool pointers", func(t *testing.T) {
		if !reflect.DeepEqual(sample.BoolPtrUnset, &trueVal) {
			t.Errorf("unset should be true")
		}
		if !reflect.DeepEqual(sample.BoolPtrSetTrue, &trueVal) {
			t.Errorf("set should remain true")
		}
		if !reflect.DeepEqual(sample.BoolPtrSetFalse, &falseVal) {
			t.Errorf("set false should remain false")
		}
	})

	t.Run("scalar types", func(t *testing.T) {
		if sample.Int != 1 {
			t.Errorf("it should initialize int")
		}
		if sample.Int8 != 8 {
			t.Errorf("it should initialize int8")
		}
		if sample.Int16 != 16 {
			t.Errorf("it should initialize int16")
		}
		if sample.Int32 != 32 {
			t.Errorf("it should initialize int32")
		}
		if sample.Int64 != 64 {
			t.Errorf("it should initialize int64")
		}
		if sample.Uint != 1 {
			t.Errorf("it should initialize uint")
		}
		if sample.Uint8 != 8 {
			t.Errorf("it should initialize uint8")
		}
		if sample.Uint16 != 16 {
			t.Errorf("it should initialize uint16")
		}
		if sample.Uint32 != 32 {
			t.Errorf("it should initialize uint32")
		}
		if sample.Uint64 != 64 {
			t.Errorf("it should initialize uint64")
		}
		if sample.Uintptr != 1 {
			t.Errorf("it should initialize uintptr")
		}
		if sample.Float32 != 1.32 {
			t.Errorf("it should initialize float32")
		}
		if sample.Float64 != 1.64 {
			t.Errorf("it should initialize float64")
		}
		if sample.BoolTrue != true {
			t.Errorf("it should initialize bool (true)")
		}
		if sample.BoolFalse != false {
			t.Errorf("it should initialize bool (false)")
		}
		if sample.String != "hello" {
			t.Errorf("it should initialize string")
		}

		if sample.IntOct != 0o1 {
			t.Errorf("it should initialize int with octal literal")
		}
		if sample.Int8Oct != 0o10 {
			t.Errorf("it should initialize int8 with octal literal")
		}
		if sample.Int16Oct != 0o20 {
			t.Errorf("it should initialize int16 with octal literal")
		}
		if sample.Int32Oct != 0o40 {
			t.Errorf("it should initialize int32 with octal literal")
		}
		if sample.Int64Oct != 0o100 {
			t.Errorf("it should initialize int64 with octal literal")
		}
		if sample.UintOct != 0o1 {
			t.Errorf("it should initialize uint with octal literal")
		}
		if sample.Uint8Oct != 0o10 {
			t.Errorf("it should initialize uint8 with octal literal")
		}
		if sample.Uint16Oct != 0o20 {
			t.Errorf("it should initialize uint16 with octal literal")
		}
		if sample.Uint32Oct != 0o40 {
			t.Errorf("it should initialize uint32 with octal literal")
		}
		if sample.Uint64Oct != 0o100 {
			t.Errorf("it should initialize uint64 with octal literal")
		}

		if sample.IntHex != 0x1 {
			t.Errorf("it should initialize int with hexadecimal literal")
		}
		if sample.Int8Hex != 0x8 {
			t.Errorf("it should initialize int8 with hexadecimal literal")
		}
		if sample.Int16Hex != 0x10 {
			t.Errorf("it should initialize int16 with hexadecimal literal")
		}
		if sample.Int32Hex != 0x20 {
			t.Errorf("it should initialize int32 with hexadecimal literal")
		}
		if sample.Int64Hex != 0x40 {
			t.Errorf("it should initialize int64 with hexadecimal literal")
		}
		if sample.UintHex != 0x1 {
			t.Errorf("it should initialize uint with hexadecimal literal")
		}
		if sample.Uint8Hex != 0x8 {
			t.Errorf("it should initialize uint8 with hexadecimal literal")
		}
		if sample.Uint16Hex != 0x10 {
			t.Errorf("it should initialize uint16 with hexadecimal literal")
		}
		if sample.Uint32Hex != 0x20 {
			t.Errorf("it should initialize uint32 with hexadecimal literal")
		}
		if sample.Uint64Hex != 0x40 {
			t.Errorf("it should initialize uint64 with hexadecimal literal")
		}

		if sample.IntBin != 0b1 {
			t.Errorf("it should initialize int with binary literal")
		}
		if sample.Int8Bin != 0b1000 {
			t.Errorf("it should initialize int8 with binary literal")
		}
		if sample.Int16Bin != 0b10000 {
			t.Errorf("it should initialize int16 with binary literal")
		}
		if sample.Int32Bin != 0b100000 {
			t.Errorf("it should initialize int32 with binary literal")
		}
		if sample.Int64Bin != 0b1000000 {
			t.Errorf("it should initialize int64 with binary literal")
		}
		if sample.UintBin != 0b1 {
			t.Errorf("it should initialize uint with binary literal")
		}
		if sample.Uint8Bin != 0b1000 {
			t.Errorf("it should initialize uint8 with binary literal")
		}
		if sample.Uint16Bin != 0b10000 {
			t.Errorf("it should initialize uint16 with binary literal")
		}
		if sample.Uint32Bin != 0b100000 {
			t.Errorf("it should initialize uint32 with binary literal")
		}
		if sample.Uint64Bin != 0b1000000 {
			t.Errorf("it should initialize uint64 with binary literal")
		}

	})

	t.Run("complex types", func(t *testing.T) {
		if sample.StructPtr == nil {
			t.Errorf("it should initialize struct pointer")
		}
		if sample.Map == nil {
			t.Errorf("it should initialize map")
		}
		if sample.Slice == nil {
			t.Errorf("it should initialize slice")
		}
	})

	t.Run("aliased types", func(t *testing.T) {
		if sample.MyInt != 1 {
			t.Errorf("it should initialize int")
		}
		if sample.MyInt8 != 8 {
			t.Errorf("it should initialize int8")
		}
		if sample.MyInt16 != 16 {
			t.Errorf("it should initialize int16")
		}
		if sample.MyInt32 != 32 {
			t.Errorf("it should initialize int32")
		}
		if sample.MyInt64 != 64 {
			t.Errorf("it should initialize int64")
		}
		if sample.MyUint != 1 {
			t.Errorf("it should initialize uint")
		}
		if sample.MyUint8 != 8 {
			t.Errorf("it should initialize uint8")
		}
		if sample.MyUint16 != 16 {
			t.Errorf("it should initialize uint16")
		}
		if sample.MyUint32 != 32 {
			t.Errorf("it should initialize uint32")
		}
		if sample.MyUint64 != 64 {
			t.Errorf("it should initialize uint64")
		}
		if sample.MyUintptr != 1 {
			t.Errorf("it should initialize uintptr")
		}
		if sample.MyFloat32 != 1.32 {
			t.Errorf("it should initialize float32")
		}
		if sample.MyFloat64 != 1.64 {
			t.Errorf("it should initialize float64")
		}
		if sample.MyBoolTrue != true {
			t.Errorf("it should initialize bool (true)")
		}
		if sample.MyBoolFalse != false {
			t.Errorf("it should initialize bool (false)")
		}
		if sample.MyString != "hello" {
			t.Errorf("it should initialize string")
		}

		if sample.MyMap == nil {
			t.Errorf("it should initialize map")
		}
		if sample.MySlice == nil {
			t.Errorf("it should initialize slice")
		}
	})

	t.Run("nested", func(t *testing.T) {
		if sample.Struct.WithDefault != "foo" {
			t.Errorf("it should set default on inner field in struct")
		}
		if sample.StructPtr == nil || sample.StructPtr.WithDefault != "foo" {
			t.Errorf("it should set default on inner field in struct pointer")
		}
		if sample.Struct.Emmbeded.Int != 1 {
			t.Errorf("it should set default on an emmbeded struct")
		}
	})

	t.Run("complex types with json", func(t *testing.T) {
		if sample.StructWithJSON.Foo != 123 {
			t.Errorf("it should initialize struct with json")
		}
		if sample.StructPtrWithJSON == nil || sample.StructPtrWithJSON.Foo != 123 {
			t.Errorf("it should initialize struct pointer with json")
		}
		if sample.MapWithJSON["foo"] != 123 {
			t.Errorf("it should initialize map with json")
		}
		if len(sample.SliceWithJSON) == 0 || sample.SliceWithJSON[0] != "foo" {
			t.Errorf("it should initialize slice with json")
		}

		t.Run("invalid json", func(t *testing.T) {
			if err := Set(&struct {
				I []int `default:"[!]"`
			}{}); err == nil {
				t.Errorf("it should return error")
			}

			if err := Set(&struct {
				I map[string]int `default:"{1}"`
			}{}); err == nil {
				t.Errorf("it should return error")
			}

			if err := Set(&struct {
				S struct {
					I []int
				} `default:"{!}"`
			}{}); err == nil {
				t.Errorf("it should return error")
			}

			if err := Set(&struct {
				S struct {
					I []int `default:"[!]"`
				}
			}{}); err == nil {
				t.Errorf("it should return error")
			}
		})
	})

	t.Run("Setter interface", func(t *testing.T) {
		if sample.Struct.Bar != 456 {
			t.Errorf("it should initialize struct")
		}
		if sample.StructPtr == nil || sample.StructPtr.Bar != 456 {
			t.Errorf("it should initialize struct pointer")
		}
	})

	t.Run("non-initial value", func(t *testing.T) {
		if sample.NonInitialString != "string" {
			t.Errorf("it should not override non-initial value")
		}
		if !reflect.DeepEqual(sample.NonInitialSlice, []int{1, 2, 3}) {
			t.Errorf("it should not override non-initial value")
		}
		if !reflect.DeepEqual(sample.NonInitialStruct, Struct{Emmbeded: Emmbeded{Int: 1}, Foo: 123, Bar: 456, WithDefault: "foo"}) {
			t.Errorf("it should not override non-initial value but set defaults for fields")
		}
		if !reflect.DeepEqual(sample.NonInitialStructPtr, &Struct{Emmbeded: Emmbeded{Int: 1}, Foo: 123, Bar: 456, WithDefault: "foo"}) {
			t.Errorf("it should not override non-initial value but set defaults for fields")
		}
	})

	t.Run("no tag", func(t *testing.T) {
		if sample.MapWithNoTag != nil {
			t.Errorf("it should not initialize pointer type (map)")
		}
		if sample.SliceWithNoTag != nil {
			t.Errorf("it should not initialize pointer type (slice)")
		}
		if sample.StructPtrWithNoTag != nil {
			t.Errorf("it should not initialize pointer type (struct)")
		}
		if sample.StructWithNoTag.WithDefault != "foo" {
			t.Errorf("it should automatically recurse into a struct even without a tag")
		}
		if !reflect.DeepEqual(sample.DeepSliceOfStructsWithNoTag, [][][]Struct{{{{Emmbeded: Emmbeded{Int: 1}, Foo: 123, Bar: 456, WithDefault: "foo"}}}}) {
			t.Errorf("it should automatically recurse into a slice of structs even without a tag")
		}
	})

	t.Run("opt-out", func(t *testing.T) {
		if sample.NoDefault != nil {
			t.Errorf("it should not be set")
		}
		if sample.NoDefaultStruct.WithDefault != "" {
			t.Errorf("it should not initialize a struct with default values")
		}
	})
}

func TestCanUpdate(t *testing.T) {
	type st struct{ Int int }

	var myStructPtr *st

	pairs := map[interface{}]bool{
		0:            true,
		123:          false,
		float64(0):   true,
		float64(123): false,
		"":           true,
		"string":     false,
		false:        true,
		true:         false,
		st{}:         true,
		st{Int: 123}: false,
		myStructPtr:  true,
		&st{}:        false,
	}
	for input, expect := range pairs {
		output := CanUpdate(input)
		if output != expect {
			t.Errorf("CanUpdate(%v) returns %v, expected %v", input, output, expect)
		}
	}
}

type Child struct {
	Name string `default:"Tom"`
	Age  int    `default:"20"`
}

type Parent struct {
	Child *Child
}

func TestPointerStructMember(t *testing.T) {
	m := Parent{Child: &Child{Name: "Jim"}}
	Set(&m)
	if m.Child.Age != 20 {
		t.Errorf("20 is expected")
	}
}

type Main struct {
	MainInt int `default:"-"`
	*Other  `default:"{}"`
}

type Other struct {
	OtherInt int `default:"-"`
}

func (s *Main) SetDefaults() {
	if CanUpdate(s.MainInt) {
		s.MainInt = 1
	}
}

func (s *Other) SetDefaults() {
	if CanUpdate(s.OtherInt) {
		s.OtherInt = 1
	}
}

func TestDefaultsSetter(t *testing.T) {
	main := &Main{}
	Set(main)
	if main.OtherInt != 1 {
		t.Errorf("expected 1 for OtherInt, got %d", main.OtherInt)
	}
	if main.MainInt != 1 {
		t.Errorf("expected 1 for MainInt, got %d", main.MainInt)
	}
}
