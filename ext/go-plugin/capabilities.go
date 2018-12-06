package main

import (
	"C"
	"encoding/json"
	"errors"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export GuestCapabilities
func GuestCapabilities(pluginName, pluginType *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getGuestCapsPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.GuestCapabilities.GuestCapabilities()
	return C.CString(r.Dump())
}

//export GuestCapability
func GuestCapability(pluginName, pluginType, cname, cplatform, cargs, cmachine *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getGuestCapsPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	machine, err := vagrant.LoadMachine(C.GoString(cmachine), nil)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	var args interface{}
	err = json.Unmarshal([]byte(C.GoString(cargs)), &args)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	cap := &vagrant.SystemCapability{
		Name:     C.GoString(cname),
		Platform: C.GoString(cplatform)}
	r.Result, r.Error = p.GuestCapabilities.GuestCapability(cap, args, machine)
	return C.CString(r.Dump())
}

//export HostCapabilities
func HostCapabilities(pluginName, pluginType *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getHostCapsPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.HostCapabilities.HostCapabilities()
	return C.CString(r.Dump())
}

//export HostCapability
func HostCapability(pluginName, pluginType, cname, cplatform, cargs, cenv *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getHostCapsPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	env, err := vagrant.LoadEnvironment(C.GoString(cenv), nil)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	var args interface{}
	err = json.Unmarshal([]byte(C.GoString(cargs)), &args)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	cap := &vagrant.SystemCapability{
		Name:     C.GoString(cname),
		Platform: C.GoString(cplatform)}
	r.Result, r.Error = p.HostCapabilities.HostCapability(cap, args, env)
	return C.CString(r.Dump())
}

//export ProviderCapabilities
func ProviderCapabilities(pluginName, pluginType *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getProviderCapsPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.ProviderCapabilities.ProviderCapabilities()
	return C.CString(r.Dump())
}

//export ProviderCapability
func ProviderCapability(pluginName, pluginType, cname, cprovider, cargs, cmach *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getProviderCapsPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	m, err := vagrant.LoadMachine(C.GoString(cmach), nil)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	var args interface{}
	err = json.Unmarshal([]byte(C.GoString(cargs)), &args)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	cap := &vagrant.ProviderCapability{
		Name:     C.GoString(cname),
		Provider: C.GoString(cprovider)}
	r.Result, r.Error = p.ProviderCapabilities.ProviderCapability(cap, args, m)
	return C.CString(r.Dump())
}

func getProviderCapsPlugin(pluginName, pluginType *C.char) (c *plugin.RemoteProviderCapabilities, err error) {
	pname := C.GoString(pluginName)
	ptype := C.GoString(pluginType)

	if ptype == "provider" {
		p, ok := Plugins.Providers[pname]
		if ok {
			c = &plugin.RemoteProviderCapabilities{
				Client:               p.Client,
				ProviderCapabilities: p.Provider}
		}
	}
	if c == nil {
		err = errors.New("Failed to locate requested plugin")
	}
	return
}

func getGuestCapsPlugin(pluginName, pluginType *C.char) (c *plugin.RemoteGuestCapabilities, err error) {
	pname := C.GoString(pluginName)
	ptype := C.GoString(pluginType)

	if ptype == "provider" {
		p, ok := Plugins.Providers[pname]
		if ok {
			c = &plugin.RemoteGuestCapabilities{
				Client:            p.Client,
				GuestCapabilities: p.Provider}
		}
	}
	if c == nil {
		err = errors.New("Failed to locate requested plugin")
	}
	return
}

func getHostCapsPlugin(pluginName, pluginType *C.char) (c *plugin.RemoteHostCapabilities, err error) {
	pname := C.GoString(pluginName)
	ptype := C.GoString(pluginType)

	if ptype == "provider" {
		p, ok := Plugins.Providers[pname]
		if ok {
			c = &plugin.RemoteHostCapabilities{
				Client:           p.Client,
				HostCapabilities: p.Provider}
		}
	}
	if c == nil {
		err = errors.New("Failed to locate requested plugin")
	}
	return
}
