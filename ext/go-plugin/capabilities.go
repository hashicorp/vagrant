package main

import (
	"C"
	"context"
	"encoding/json"
	"errors"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export GuestCapabilities
func GuestCapabilities(pluginName, pluginType *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.GuestCapabilities)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	r.Result, r.Error = p.GuestCapabilities()
	return r.Dump()
}

//export GuestCapability
func GuestCapability(pluginName, pluginType, cname, cplatform, cargs, cmachine *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.GuestCapabilities)
	if !ok {
		r.Error = errors.New("Failed to load requested plugin")
		return r.Dump()
	}
	machine, err := vagrant.LoadMachine(to_gs(cmachine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var args interface{}
	err = json.Unmarshal([]byte(to_gs(cargs)), &args)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	cap := &vagrant.SystemCapability{
		Name:     to_gs(cname),
		Platform: to_gs(cplatform)}
	ctx := context.Background()
	r.Result, r.Error = p.GuestCapability(ctx, cap, args, machine)
	return r.Dump()
}

//export HostCapabilities
func HostCapabilities(pluginName, pluginType *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.HostCapabilities)
	if !ok {
		r.Error = errors.New("Failed to load requested plugin")
		return r.Dump()
	}

	r.Result, r.Error = p.HostCapabilities()
	return r.Dump()
}

//export HostCapability
func HostCapability(pluginName, pluginType, cname, cplatform, cargs, cenv *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.HostCapabilities)
	if !ok {
		r.Error = errors.New("Failed to load requested plugin")
		return r.Dump()
	}

	env, err := vagrant.LoadEnvironment(to_gs(cenv), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var args interface{}
	err = json.Unmarshal([]byte(to_gs(cargs)), &args)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	cap := &vagrant.SystemCapability{
		Name:     to_gs(cname),
		Platform: to_gs(cplatform)}
	ctx := context.Background()
	r.Result, r.Error = p.HostCapability(ctx, cap, args, env)
	return r.Dump()
}

//export ProviderCapabilities
func ProviderCapabilities(pluginName, pluginType *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.ProviderCapabilities)
	if !ok {
		r.Error = errors.New("Failed to load requested plugin")
		return r.Dump()
	}

	r.Result, r.Error = p.ProviderCapabilities()
	return r.Dump()
}

//export ProviderCapability
func ProviderCapability(pluginName, pluginType, cname, cprovider, cargs, cmach *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.ProviderCapabilities)
	if !ok {
		r.Error = errors.New("Failed to load requested plugin")
		return r.Dump()
	}

	m, err := vagrant.LoadMachine(to_gs(cmach), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var args interface{}
	err = json.Unmarshal([]byte(to_gs(cargs)), &args)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	cap := &vagrant.ProviderCapability{
		Name:     to_gs(cname),
		Provider: to_gs(cprovider)}
	ctx := context.Background()
	r.Result, r.Error = p.ProviderCapability(ctx, cap, args, m)
	return r.Dump()
}
