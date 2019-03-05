package main

import (
	"C"
	"encoding/json"
	"errors"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export ConfigLoad
func ConfigLoad(pluginName, pluginType, data *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(*plugin.RemoteConfig)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	var cdata map[string]interface{}
	r.Error = json.Unmarshal([]byte(to_gs(data)), &cdata)
	if r.Error != nil {
		return r.Dump()
	}
	r.Result, r.Error = p.Config.ConfigLoad(cdata)
	return r.Dump()
}

//export ConfigAttributes
func ConfigAttributes(pluginName, pluginType *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(*plugin.RemoteConfig)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	r.Result, r.Error = p.Config.ConfigAttributes()
	return r.Dump()
}

//export ConfigValidate
func ConfigValidate(pluginName, pluginType, data, machData *C.char) *C.char {
	var m *vagrant.Machine
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(*plugin.RemoteConfig)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	var cdata map[string]interface{}
	r.Error = json.Unmarshal([]byte(to_gs(data)), &cdata)
	if r.Error != nil {
		return r.Dump()
	}
	m, r.Error = vagrant.LoadMachine(to_gs(machData), nil)
	if r.Error != nil {
		return r.Dump()
	}
	r.Result, r.Error = p.Config.ConfigValidate(cdata, m)
	return r.Dump()
}

//export ConfigFinalize
func ConfigFinalize(pluginName, pluginType, data *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), to_gs(pluginType))
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(*plugin.RemoteConfig)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	var cdata map[string]interface{}
	r.Error = json.Unmarshal([]byte(to_gs(data)), &cdata)
	if r.Error == nil {
		r.Result, r.Error = p.Config.ConfigFinalize(cdata)
	}
	return r.Dump()
}
