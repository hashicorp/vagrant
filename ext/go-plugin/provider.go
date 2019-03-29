package main

import (
	"C"
	"context"
	"encoding/json"
	"errors"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export ListProviders
func ListProviders() *C.char {
	list := map[string]interface{}{}
	r := &Response{Result: list}
	if Plugins == nil {
		return r.Dump()
	}
	for n, p := range Plugins.Providers {
		list[n] = p.Provider.Info()
	}
	r.Result = list
	return r.Dump()
}

//export ProviderAction
func ProviderAction(providerName *C.char, actionName *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	aName := to_gs(actionName)
	ctx := context.Background()
	r.Result, r.Error = p.Action(ctx, aName, m)
	return r.Dump()
}

//export ProviderIsInstalled
func ProviderIsInstalled(providerName *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	ctx := context.Background()
	r.Result, r.Error = p.IsInstalled(ctx, m)
	return r.Dump()
}

//export ProviderIsUsable
func ProviderIsUsable(providerName *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}

	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	ctx := context.Background()
	r.Result, r.Error = p.IsUsable(ctx, m)
	return r.Dump()
}

//export ProviderMachineIdChanged
func ProviderMachineIdChanged(providerName *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	ctx := context.Background()
	r.Error = p.MachineIdChanged(ctx, m)
	return r.Dump()
}

//export ProviderRunAction
func ProviderRunAction(providerName *C.char, actName *C.char, runData *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	aName := to_gs(actName)
	var rData interface{}
	err = json.Unmarshal([]byte(to_gs(runData)), &rData)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	ctx := context.Background()
	r.Result, r.Error = p.RunAction(ctx, aName, rData, m)
	return r.Dump()
}

//export ProviderSshInfo
func ProviderSshInfo(providerName *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	ctx := context.Background()
	r.Result, r.Error = p.SshInfo(ctx, m)
	return r.Dump()
}

//export ProviderState
func ProviderState(providerName *C.char, machData *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(providerName), "provider")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.Provider)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machData), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	ctx := context.Background()
	r.Result, r.Error = p.State(ctx, m)
	return r.Dump()
}
