package main

import (
	"C"
	"encoding/json"
	"errors"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

//export ListSyncedFolders
func ListSyncedFolders() *C.char {
	list := map[string]interface{}{}
	r := &Response{Result: list}
	if Plugins == nil {
		return r.Dump()
	}
	for n, p := range Plugins.SyncedFolders {
		list[n] = p.SyncedFolder.Info()
	}
	r.Result = list
	return r.Dump()
}

//export SyncedFolderCleanup
func SyncedFolderCleanup(pluginName, machine, opts *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), "synced_folder")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.SyncedFolder)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}

	m, err := vagrant.LoadMachine(to_gs(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(to_gs(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.Cleanup(m, o)
	return r.Dump()
}

//export SyncedFolderDisable
func SyncedFolderDisable(pluginName, machine, folders, opts *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), "synced_folder")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.SyncedFolder)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var f vagrant.FolderList
	r.Error = json.Unmarshal([]byte(to_gs(folders)), &f)
	if r.Error != nil {
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(to_gs(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.Disable(m, f, o)
	return r.Dump()
}

//export SyncedFolderEnable
func SyncedFolderEnable(pluginName, machine, folders, opts *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), "synced_folder")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.SyncedFolder)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var f vagrant.FolderList
	r.Error = json.Unmarshal([]byte(to_gs(folders)), &f)
	if r.Error != nil {
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(to_gs(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.Enable(m, f, o)
	return r.Dump()
}

//export SyncedFolderIsUsable
func SyncedFolderIsUsable(pluginName, machine *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), "synced_folder")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.SyncedFolder)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	r.Result, r.Error = p.IsUsable(m)
	return r.Dump()
}

//export SyncedFolderPrepare
func SyncedFolderPrepare(pluginName, machine, folders, opts *C.char) *C.char {
	r := &Response{}
	i, err := Plugins.PluginLookup(to_gs(pluginName), "synced_folder")
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	p, ok := i.(plugin.SyncedFolder)
	if !ok {
		r.Error = errors.New("failed to load requested plugin")
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(to_gs(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var f vagrant.FolderList
	r.Error = json.Unmarshal([]byte(to_gs(folders)), &f)
	if r.Error != nil {
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(to_gs(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.Prepare(m, f, o)
	return r.Dump()
}
