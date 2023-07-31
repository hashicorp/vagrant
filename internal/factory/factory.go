// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

// Package factory contains a "factory" pattern based on argmapper.
//
// A Factory can be used to register factory methods to create some predefined
// type or interface implementation. These functions are argmapper functions so
// converters and so on can be used as part of instantiation.
package factory

import (
	"fmt"
	"reflect"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/dynamic"
)

// Factory keeps track of named dependency-injected factory functions to
// create an implementation of an interface.
type Factory struct {
	iface reflect.Type
	funcs map[string]*argmapper.Func
}

// New creates a Factory for the interface iface. The parameter
// iface should be a nil pointer to the interface type. Example: (*iface)(nil).
func New(iface interface{}) (*Factory, error) {
	// Get the interface type
	it := reflect.TypeOf(iface)
	if k := it.Kind(); k != reflect.Ptr {
		return nil, fmt.Errorf("iface must be a pointer to an interface, got %s", k)
	}
	it = it.Elem()
	if k := it.Kind(); k != reflect.Interface {
		return nil, fmt.Errorf("iface must be a pointer to an interface, got %s", k)
	}

	return &Factory{iface: it, funcs: make(map[string]*argmapper.Func)}, nil
}

// Register registers a factory function named name for the interface.
//
// This will error if the function given doesn't result in a single non-error
// output that implements the interface registered with this factory. The
// function return signature can be: (T) or (T, error) where T implements
// the interface type for this factory.
//
// T is allowed to be a literal interface{} type. In this case, it is the
// callers responsibility to ensure the result is the proper type.
//
// fn may take any number and types of inputs. It is the callers responsibilty
// when using Func and Call to pass in the required parameters.
func (f *Factory) Register(name string, fn interface{}) error {
	ff, err := argmapper.NewFunc(fn,
		argmapper.Logger(dynamic.Logger))
	if err != nil {
		return err
	}

	outputs := ff.Output().Values()
	if len(outputs) != 1 {
		return fmt.Errorf("factory functions should have exactly one output: the implementation")
	}

	// We allow "interface{}" to pass through, in which case we trust that
	// the callback is generating the correct type.
	typ := outputs[0].Type
	if typ != ifaceType && !typ.Implements(f.iface) {
		return fmt.Errorf("factory output should implement interface: %s", f.iface)
	}

	f.funcs[name] = ff
	return nil
}

// Func returns the factory function named name. This can then be used to
// call and instantiate the factory interface type.
func (f *Factory) Func(name string) *argmapper.Func {
	return f.funcs[name]
}

// Registered returns the names registered with this factory.
func (f *Factory) Registered() []string {
	result := make([]string, 0, len(f.funcs))
	for k := range f.funcs {
		result = append(result, k)
	}

	return result
}

// Copy returns a copy of Factory. Any registrations on the copy will not
// reflect the original and vice versa.
func (f *Factory) Copy() *Factory {
	// Copy
	f2 := *f

	// Build new funcs
	f2.funcs = map[string]*argmapper.Func{}
	for k, v := range f.funcs {
		f2.funcs[k] = v
	}

	return &f2
}

var ifaceType = reflect.TypeOf((*interface{})(nil)).Elem()
