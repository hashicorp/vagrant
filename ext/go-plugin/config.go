package main

import (
	"C"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export ConfigLoad
func ConfigLoad(pluginName, pluginType, data *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getConfigPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	var cdata map[string]interface{}
	r.Error = json.Unmarshal([]byte(C.GoString(data)), &cdata)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Config.ConfigLoad(cdata)
	return C.CString(r.Dump())
}

//export ConfigAttributes
func ConfigAttributes(pluginName, pluginType *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getConfigPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Config.ConfigAttributes()
	return C.CString(r.Dump())
}

//export ConfigValidate
func ConfigValidate(pluginName, pluginType, data, machData *C.char) *C.char {
	var m *vagrant.Machine
	r := vagrant.Response{}
	p, err := getConfigPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	var cdata map[string]interface{}
	r.Error = json.Unmarshal([]byte(C.GoString(data)), &cdata)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	m, r.Error = vagrant.LoadMachine(C.GoString(machData), nil)
	if r.Error != nil {
		return C.CString(r.Dump())
	}
	r.Result, r.Error = p.Config.ConfigValidate(cdata, m)
	return C.CString(r.Dump())
}

//export ConfigFinalize
func ConfigFinalize(pluginName, pluginType, data *C.char) *C.char {
	r := vagrant.Response{}
	p, err := getConfigPlugin(pluginName, pluginType)
	if err != nil {
		r.Error = err
		return C.CString(r.Dump())
	}
	var cdata map[string]interface{}
	r.Error = json.Unmarshal([]byte(C.GoString(data)), &cdata)
	if r.Error == nil {
		println("FINALIZE HAS VALID CONFIG")
		r.Result, r.Error = p.Config.ConfigFinalize(cdata)
	}
	fmt.Printf("Full result: %s\n", r.Dump())
	return C.CString(r.Dump())
}

func getConfigPlugin(pluginName, pluginType *C.char) (c *plugin.RemoteConfig, err error) {
	pname := C.GoString(pluginName)
	ptype := C.GoString(pluginType)

	if ptype == "provider" {
		p, ok := Plugins.Providers[pname]
		if ok {
			c = &plugin.RemoteConfig{
				Client: p.Client,
				Config: p.Provider}
		}
	}
	if c == nil {
		err = errors.New("Failed to locate requested plugin")
	}
	return
}
