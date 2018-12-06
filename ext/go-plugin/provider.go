package main

import (
	"C"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export ListProviders
func ListProviders() *C.char {
	list := map[string]interface{}{}
	r := vagrant.Response{Result: list}
	if Plugins == nil {
		return C.CString(r.Dump())
	}
	for n, p := range Plugins.Providers {
		list[n] = p.Provider.Info()
	}
	r.Result = list
	return C.CString(r.Dump())
}

//export ProviderAction
func ProviderAction(providerName *C.char, actionName *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	aName := C.GoString(actionName)
	r.Result, r.Error = p.Provider.Action(aName, m)
	return C.CString(r.Dump())
}

//export ProviderIsInstalled
func ProviderIsInstalled(providerName *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Provider.IsInstalled(m)
	return C.CString(r.Dump())
}

//export ProviderIsUsable
func ProviderIsUsable(providerName *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Provider.IsUsable(m)
	return C.CString(r.Dump())
}

//export ProviderMachineIdChanged
func ProviderMachineIdChanged(providerName *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Error = p.Provider.MachineIdChanged(m)
	return C.CString(r.Dump())
}

//export ProviderRunAction
func ProviderRunAction(providerName *C.char, actName *C.char, runData *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	aName := C.GoString(actName)
	rData := C.GoString(runData)
	r.Result, r.Error = p.Provider.RunAction(aName, rData, m)
	return C.CString(r.Dump())
}

//export ProviderSshInfo
func ProviderSshInfo(providerName *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Provider.SshInfo(m)
	return C.CString(r.Dump())
}

//export ProviderState
func ProviderState(providerName *C.char, machData *C.char) *C.char {
	var p *plugin.RemoteProvider
	var m *vagrant.Machine

	r := vagrant.Response{}
	p, r.Error = getProvider(providerName)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Provider.State(m)
	return C.CString(r.Dump())
}

func getProvider(pName *C.char) (*plugin.RemoteProvider, error) {
	providerName := C.GoString(pName)
	p, ok := Plugins.Providers[providerName]
	if !ok {
		Plugins.Logger.Error("error fetching plugin", "type", "provider",
			"name", providerName, "reason", "not found")
		return nil, errors.New(fmt.Sprintf(
			"failed to locate provider plugin `%s`", providerName))
	}
	return p, nil
}

// Loads the machine data JSON string to ensure that it is
// valid JSON. Returns the converted GoString to be used
// internally
func validateMachine(machineData *C.char) (string, error) {
	mData := C.GoString(machineData)
	Plugins.Logger.Debug("received machine info", "data", mData)
	err := json.Unmarshal([]byte(mData), &vagrant.Machine{})
	if err != nil {
		fmt.Printf("Error: %s\n", err)
		err = errors.New(fmt.Sprintf(
			"failed to load vagrant environment information - %s", err))
	}
	return mData, err
}
