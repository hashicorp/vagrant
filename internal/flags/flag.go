// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package flags

import (
	"fmt"
	"os"
	"strconv"
	"strings"
)

type Type uint

const (
	UnsetType     Type = iota // Unset
	ArrayType                 // Array
	BooleanType               // Boolean
	FloatType                 // Float
	IncrementType             // Increment
	IntegerType               // Integer
	MapType                   // Map
	StringType                // String
)

type FlagModifier func(f *Flag)
type FlagProcessor func(f *Flag, v interface{}) (interface{}, error)
type FlagCallback func(f *Flag) error

// Add long name aliases for flag
func Alias(aliases ...string) FlagModifier {
	return func(f *Flag) {
		for _, a := range aliases {
			f.aliases = append(f.aliases, a)
		}
	}
}

// Set description of flag
func Description(d string) FlagModifier {
	return func(f *Flag) {
		f.description = d
	}
}

// Mark flag as being required
func Required() FlagModifier {
	return func(f *Flag) {
		f.required = true
	}
}

// Mark flag as being optional (default state)
func Optional() FlagModifier {
	return func(f *Flag) {
		f.required = false
	}
}

// Prevent flag from being displayed
func Hidden() FlagModifier {
	return func(f *Flag) {
		f.hidden = true
	}
}

// Set default value for flag
func DefaultValue(v interface{}) FlagModifier {
	return func(f *Flag) {
		f.typeCheck(v)
		f.defaultValue = v
	}
}

// Set environment variable to read for flag value
func EnvVar(name string) FlagModifier {
	return func(f *Flag) {
		f.envVar = name
	}
}

// Set short name for flag
func ShortName(n rune) FlagModifier {
	return func(f *Flag) {
		f.shortName = n
	}
}

// Set the subtype of the flag (used for array and map types)
func SetSubtype(t Type) FlagModifier {
	return func(f *Flag) {
		f.subkind = t
	}
}

// Add a processor to be executed before the flag value is
// set. The processor receives the current value to be set
// into the flag. The value returned by the process will be
// the value actually set into the flag.
func AddProcessor(fn FlagProcessor) FlagModifier {
	return func(f *Flag) {
		f.processors = append(f.processors, fn)
	}
}

// Add a callback to be executed when flag is visited before
// the flag value is set. This can be used to modify the
// final value set.
func AddCallback(fn FlagCallback) FlagModifier {
	return func(f *Flag) {
		f.callbacks = append(f.callbacks, fn)
	}
}

// Set value into custom pointer
func customVar(v interface{}) FlagModifier {
	return func(f *Flag) {
		f.ptrTypeCheck(v)
		f.value = v
		f.ptr = true
	}
}

type Flag struct {
	aliases      []string        // long name aliases
	called       bool            // mark if called via cli
	callbacks    []FlagCallback  // callback functions
	defaultValue interface{}     // default value when not updated
	description  string          // description of flag
	envVar       string          // environment variable to check for value
	group        *Group          // group flag is attached to
	hidden       bool            // flag is hidden from display
	longName     string          // long name of flag
	matchedName  string          // long or short name matched for flag (includes aliases)
	processors   []FlagProcessor // processor functions
	ptr          bool            // mark if value is pointer
	required     bool            // mark if flag requires value set
	shortName    rune            // short name of flag
	kind         Type            // data type of value
	subkind      Type            // data type of values within array or map type
	updated      bool            // value was updated (either by env var or cli)
	value        interface{}     // value for flag
}

// Create a new flag
func newFlag(
	name string, // long name of flag
	kind Type, // data type of the flag
	group *Group, // group flag is attached to
	modifiers ...FlagModifier, // any modifier functions
) *Flag {
	if group == nil {
		panic("flag must be attached to group")
	}
	f := &Flag{
		longName: name,
		kind:     kind,
		group:    group,
	}
	group.flags = append(group.flags, f)
	for _, fn := range modifiers {
		fn(f)
	}
	if kind == BooleanType {
		Alias(fmt.Sprintf("no-%s", f.longName))(f)
	}

	return f
}

// List of aliases for this flag
func (f *Flag) Aliases() []string {
	return f.aliases
}

// Flag value was set via CLI
func (f *Flag) Called() bool {
	return f.called
}

// Flag name (long, short, aliases) matched on CLI
func (f *Flag) CalledAs() string {
	return f.matchedName
}

// Default value assigned to flag
func (f *Flag) DefaultValue() interface{} {
	return f.defaultValue
}

// Description of flag usage
func (f *Flag) Description() string {
	return f.description
}

// Environment variable name used to populate flag value
func (f *Flag) EnvVar() string {
	return f.envVar
}

// Group flag is attached to
func (f *Flag) Group() *Group {
	return f.group
}

// Flag is hidden from display
func (f *Flag) Hidden() bool {
	return f.hidden
}

// Long name of the flag
func (f *Flag) LongName() string {
	return f.longName
}

// Flag is required to be set
func (f *Flag) Required() bool {
	return f.required
}

// Short name of the flag
func (f *Flag) ShortName() rune {
	return f.shortName
}

// Flag value was set via CLI or environment variable
func (f *Flag) Updated() bool {
	return f.updated
}

// Value assigned to flag
func (f *Flag) Value() interface{} {
	if f.ptr {
		switch f.kind {
		case ArrayType:
			switch f.subkind {
			case BooleanType:
				return *(f.value.(*[]bool))
			case FloatType:
				return *(f.value.(*[]float64))
			case IntegerType:
				return *(f.value.(*[]int64))
			case StringType:
				return *(f.value.(*[]string))
			default:
				panic("unsupported array subtype: " + f.subkind.String())
			}
		case BooleanType:
			return *(f.value.(*bool))
		case FloatType:
			return *(f.value.(*float64))
		case IncrementType, IntegerType:
			return *(f.value.(*int64))
		case MapType:
			switch f.subkind {
			case BooleanType:
				return *(f.value.(*map[string]bool))
			case FloatType:
				return *(f.value.(*map[string]float64))
			case IntegerType:
				return *(f.value.(*map[string]int64))
			case StringType:
				return *(f.value.(*map[string]string))
			default:
				panic("unsupported map subtype: " + f.subkind.String())
			}
		case StringType:
			return *(f.value.(*string))
		}
	}
	return f.value
}

// Initialize the flag to make ready for parsing. This is called
// by the Set before parsing.
func (f *Flag) init() error {
	// if the value is already set, the flag has been previously
	// used so we should consider it invalid
	if f.updated || f.called {
		return fmt.Errorf("flag has already been used")
	}
	// If the value is a custom variable then we don't need to initialize
	if !f.ptr {
		// Now we want to initialize our value so it can
		// be modified as needed.
		switch f.kind {
		case ArrayType:
			switch f.subkind {
			case BooleanType:
				f.value = []bool{}
			case FloatType:
				f.value = []float64{}
			case IntegerType:
				f.value = []int64{}
			case StringType:
				f.value = []string{}
			default:
				panic("invalid subtype for array: " + f.subkind.String())
			}
		case BooleanType:
			var val bool
			f.value = val
		case FloatType:
			var val float64
			f.value = val
		case IncrementType, IntegerType:
			var val int64
			f.value = val
		case MapType:
			switch f.subkind {
			case BooleanType:
				f.value = map[string]bool{}
			case FloatType:
				f.value = map[string]float64{}
			case IntegerType:
				f.value = map[string]int64{}
			case StringType:
				f.value = map[string]string{}
			default:
				panic("invalid subtype for map: " + f.subkind.String())
			}
		case StringType:
			var val string
			f.value = val
		}
	}

	// Check if we have an environment variable configured, and if it
	// is set, then set the value into the flag
	if f.envVar != "" {
		if eval := os.Getenv(f.envVar); eval != "" {
			if err := f.setValue(eval); err != nil {
				return err
			}
			f.updated = true
		}
	}
	return nil
}

// Marks the flag as being called from the CLI and sets
// the flag name used.
func (f *Flag) markCalled(name string) {
	defer func() {
		f.matchedName = name
		f.called = true
		f.updated = true
	}()
	if f.longName == name || string(f.shortName) == name {
		return
	}
	for _, n := range f.aliases {
		if n == name {
			return
		}
	}
	panic(fmt.Sprintf(
		"matched flag name (%s) is not a valid name for this flag (%s)",
		name, f.longName))
}

// Set a value into the flag
func (f *Flag) setValue(v string) (err error) {
	switch f.kind {
	case ArrayType:
		err = f.setValueArray(v)
	case BooleanType:
		err = f.setValueBoolean(v)
	case FloatType:
		err = f.setValueFloat(v)
	case IncrementType:
		err = f.setValueIncrement(v)
	case MapType:
		err = f.setValueMap(v)
	case StringType:
		err = f.setValueString(v)
	default:
		err = fmt.Errorf("invalid type, cannot set value")
	}
	if err != nil {
		return
	}

	for _, fn := range f.callbacks {
		if err = fn(f); err != nil {
			return
		}
	}
	return
}

// Set value into map type
func (f *Flag) setValueMap(v string) (err error) {
	parts := strings.SplitN(v, "=", 2)
	if len(parts) != 2 {
		return fmt.Errorf("invalid value passed for map flag - %s", v)
	}
	key, value := parts[0], parts[1]
	val, err := f.convertValue(value)
	if err != nil {
		return
	}
	for _, fn := range f.processors {
		if val, err = fn(f, val); err != nil {
			return
		}
	}
	switch f.subkind {
	case BooleanType:
		var m map[string]bool
		if f.ptr {
			m = *(f.value.(*map[string]bool))
		} else {
			m = f.value.(map[string]bool)
		}
		m[key] = val.(bool)
	case FloatType:
		var m map[string]float64
		if f.ptr {
			m = *(f.value.(*map[string]float64))
		} else {
			m = f.value.(map[string]float64)
		}
		m[key] = val.(float64)
	case IntegerType:
		var m map[string]int64
		if f.ptr {
			m = *(f.value.(*map[string]int64))
		} else {
			m = f.value.(map[string]int64)
		}
		m[key] = val.(int64)
	case StringType:
		var m map[string]string
		if f.ptr {
			m = *(f.value.(*map[string]string))
		} else {
			m = f.value.(map[string]string)
		}
		m[key] = val.(string)
	default:
		return fmt.Errorf("invalid subtype configured for map flag - %s", f.subkind.String())
	}

	return
}

// Set value into array type
func (f *Flag) setValueArray(val string) (err error) {
	v, err := f.convertValue(val)
	if err != nil {
		return
	}
	for _, fn := range f.processors {
		if v, err = fn(f, v); err != nil {
			return
		}
	}

	switch f.subkind {
	case BooleanType:
		var array []bool
		if f.ptr {
			array = *(f.value.(*[]bool))
		} else {
			array = f.value.([]bool)
		}
		newArray := make([]bool, len(array)+1)
		copy(newArray, array)
		newArray[len(newArray)-1] = v.(bool)
		if f.ptr {
			*(f.value.(*[]bool)) = newArray
		} else {
			f.value = newArray
		}
	case FloatType:
		var array []float64
		if f.ptr {
			array = *(f.value.(*[]float64))
		} else {
			array = f.value.([]float64)
		}
		newArray := make([]float64, len(array)+1)
		copy(newArray, array)
		newArray[len(newArray)-1] = v.(float64)
		if f.ptr {
			*(f.value.(*[]float64)) = newArray
		} else {
			f.value = newArray
		}
	case IntegerType:
		var array []int64
		if f.ptr {
			array = *(f.value.(*[]int64))
		} else {
			array = f.value.([]int64)
		}
		newArray := make([]int64, len(array)+1)
		copy(newArray, array)
		newArray[len(newArray)-1] = v.(int64)
		if f.ptr {
			*(f.value.(*[]int64)) = newArray
		} else {
			f.value = newArray
		}
	case StringType:
		var array []string
		if f.ptr {
			array = *(f.value.(*[]string))
		} else {
			array = f.value.([]string)
		}
		newArray := make([]string, len(array)+1)
		copy(newArray, array)
		newArray[len(newArray)-1] = v.(string)
		if f.ptr {
			*(f.value.(*[]string)) = newArray
		} else {
			f.value = newArray
		}
	default:
		return fmt.Errorf("invalid subtype configured for array flag - %s", f.subkind.String())
	}

	return nil
}

// Set value into boolean type
func (f *Flag) setValueBoolean(val string) (err error) {
	v, err := f.convertValue(val)
	if err != nil {
		return
	}
	for _, fn := range f.processors {
		if v, err = fn(f, v); err != nil {
			return
		}
	}

	if f.ptr {
		*(f.value.(*bool)) = v.(bool)
		return
	}

	f.value = v
	return
}

// Set value into float type
func (f *Flag) setValueFloat(val string) (err error) {
	v, err := f.convertValue(val)
	if err != nil {
		return
	}
	for _, fn := range f.processors {
		if v, err = fn(f, v); err != nil {
			return
		}
	}

	if f.ptr {
		*(f.value.(*float64)) = v.(float64)
		return
	}

	f.value = v
	return
}

// Set value into integer type
func (f *Flag) setValueInteger(val string) (err error) {
	v, err := f.convertValue(val)
	if err != nil {
		return
	}
	for _, fn := range f.processors {
		if v, err = fn(f, v); err != nil {
			return
		}
	}

	if f.ptr {
		*(f.value.(*int64)) = v.(int64)
		return
	}

	f.value = v
	return
}

// Set value into string type
func (f *Flag) setValueString(val string) (err error) {
	v, err := f.convertValue(val)
	if err != nil {
		return
	}
	for _, fn := range f.processors {
		if v, err = fn(f, v); err != nil {
			return
		}
	}

	if f.ptr {
		*(f.value.(*string)) = v.(string)
		return
	}

	f.value = v
	return
}

// Set value on increment type
func (f *Flag) setValueIncrement(val string) (err error) {
	if f.ptr {
		*(f.value.(*int64)) = *(f.value.(*int64)) + 1
		return
	}

	f.value = interface{}(f.value.(int64) + 1)
	return
}

// Convert given value to expected type
func (f *Flag) convertValue(v string) (interface{}, error) {
	switch f.kind {
	case ArrayType, MapType:
		return f.doConvert(v, f.subkind)
	case IncrementType:
		return 1, nil
	default:
		return f.doConvert(v, f.kind)
	}
}

// Actually do the conversion based on type
func (f *Flag) doConvert(v string, t Type) (interface{}, error) {
	switch t {
	case BooleanType:
		b, err := strconv.ParseBool(v)
		if err != nil {
			return nil, err
		}
		return b, nil
	case FloatType:
		pf, err := strconv.ParseFloat(v, 64)
		if err != nil {
			return nil, err
		}
		return pf, nil
	case IntegerType:
		pi, err := strconv.ParseInt(v, 10, 64)
		if err != nil {
			return nil, err
		}
		return pi, nil
	case StringType:
		// Original values are strings, so just return the value
		return v, nil
	default:
		return nil, fmt.Errorf("invalid type for conversion - %s", f.kind.String())
	}
}

// Check that the value given is the type expected by the flag. This
// will panic on unexpected type.
func (f *Flag) typeCheck(v interface{}) {
	switch f.kind {
	case ArrayType:
		switch f.subkind {
		case BooleanType:
			if _, ok := v.([]bool); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: []bool received: %T", v))
			}
		case FloatType:
			if _, ok := v.([]float64); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: []float64 received: %T", v))
			}
		case IntegerType:
			if _, ok := v.([]int64); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: []int64 received: %T", v))
			}
		case StringType:
			if _, ok := v.([]string); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: []string received: %T", v))
			}
		default:
			panic("invalid subtype for array: " + f.subkind.String())
		}
	case BooleanType:
		if _, ok := v.(bool); !ok {
			panic(fmt.Sprintf("invalid variable type - expected: bool received: %T", v))
		}
	case FloatType:
		if _, ok := v.(float64); !ok {
			panic(fmt.Sprintf("invalid variable type - expected: float64 received: %T", v))
		}
	case IncrementType, IntegerType:
		if _, ok := v.(int64); !ok {
			panic(fmt.Sprintf("invalid variable type - expected: int64 received: %T", v))
		}
	case MapType:
		switch f.subkind {
		case BooleanType:
			if _, ok := v.(map[string]bool); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: map[string]bool received: %T", v))
			}
		case FloatType:
			if _, ok := v.(map[string]float64); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: map[string]float64 received: %T", v))
			}
		case IntegerType:
			if _, ok := v.(map[string]int64); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: map[string]int64 received: %T", v))
			}
		case StringType:
			if _, ok := v.(map[string]string); !ok {
				panic(fmt.Sprintf("invalid variable type - expected: map[string]string received: %T", v))
			}
		default:
			panic("invalid subtype for map: " + f.subkind.String())
		}
	case StringType:
		if _, ok := v.(string); !ok {
			panic(fmt.Sprintf("invalid variable type - expected: string received: %T", v))
		}
	}
}

// Check that the value given is a pointer to the type expected by the flag. This
// will panic on unexpected type.
func (f *Flag) ptrTypeCheck(v interface{}) {
	switch f.kind {
	case ArrayType:
		switch f.subkind {
		case BooleanType:
			if c, ok := v.(*[]bool); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *[]bool received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("array pointer value cannot be nil - %#v", c))
				}
			}
		case FloatType:
			if c, ok := v.(*[]float64); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *[]float64 received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("array pointer value cannot be nil - %#v", c))
				}
			}
		case IntegerType:
			if c, ok := v.(*[]int64); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *[]int64 received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("array pointer value cannot be nil - %#v", c))
				}
			}
		case StringType:
			if c, ok := v.(*[]string); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *[]string received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("array pointer value cannot be nil - %#v", c))
				}
			}
		default:
			panic("invalid subtype for array: " + f.subkind.String())
		}
	case BooleanType:
		if _, ok := v.(*bool); !ok {
			panic(fmt.Sprintf("invalid pointer variable - expected *bool received %T", v))
		}
	case FloatType:
		if _, ok := v.(*float64); !ok {
			panic(fmt.Sprintf("invalid pointer variable - expected *float64 received %T", v))
		}
	case IncrementType, IntegerType:
		if _, ok := v.(*int64); !ok {
			panic(fmt.Sprintf("invalid pointer variable - expected *int64 received %T", v))
		}
	case MapType:
		switch f.subkind {
		case BooleanType:
			if c, ok := v.(*map[string]bool); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *map[string]bool received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("map pointer value cannot be nil - %#v", c))
				}
			}
		case FloatType:
			if c, ok := v.(*map[string]float64); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *map[string]float64 received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("map pointer value cannot be nil - %#v", c))
				}
			}
		case IntegerType:
			if c, ok := v.(*map[string]int64); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *map[string]int64 received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("map pointer value cannot be nil - %#v", c))
				}
			}
		case StringType:
			if c, ok := v.(*map[string]string); !ok {
				panic(fmt.Sprintf("invalid pointer variable - expected: *map[string]string received: %T", v))
			} else {
				if *c == nil {
					panic(fmt.Sprintf("map pointer value cannot be nil - %#v", c))
				}
			}
		default:
			panic("invalid subtype for array: " + f.subkind.String())
		}
	case StringType:
		if _, ok := v.(*string); !ok {
			panic(fmt.Sprintf("invalid pointer variable - expected *string received %T", v))
		}
	}
}
