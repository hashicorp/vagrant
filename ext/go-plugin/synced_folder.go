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
	p, err := getSyncedFolderPlugin(pluginName)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(C.GoString(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(C.GoString(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.SyncedFolder.Cleanup(m, o)
	return r.Dump()
}

//export SyncedFolderDisable
func SyncedFolderDisable(pluginName, machine, folders, opts *C.char) *C.char {
	r := &Response{}
	p, err := getSyncedFolderPlugin(pluginName)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(C.GoString(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var f vagrant.FolderList
	r.Error = json.Unmarshal([]byte(C.GoString(folders)), &f)
	if r.Error != nil {
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(C.GoString(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.SyncedFolder.Disable(m, f, o)
	return r.Dump()
}

//export SyncedFolderEnable
func SyncedFolderEnable(pluginName, machine, folders, opts *C.char) *C.char {
	r := &Response{}
	p, err := getSyncedFolderPlugin(pluginName)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(C.GoString(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var f vagrant.FolderList
	r.Error = json.Unmarshal([]byte(C.GoString(folders)), &f)
	if r.Error != nil {
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(C.GoString(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.SyncedFolder.Enable(m, f, o)
	return r.Dump()
}

//export SyncedFolderIsUsable
func SyncedFolderIsUsable(pluginName, machine *C.char) *C.char {
	r := &Response{}
	p, err := getSyncedFolderPlugin(pluginName)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(C.GoString(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	r.Result, r.Error = p.SyncedFolder.IsUsable(m)
	return r.Dump()
}

//export SyncedFolderPrepare
func SyncedFolderPrepare(pluginName, machine, folders, opts *C.char) *C.char {
	r := &Response{}
	p, err := getSyncedFolderPlugin(pluginName)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	m, err := vagrant.LoadMachine(C.GoString(machine), nil)
	if err != nil {
		r.Error = err
		return r.Dump()
	}
	var f vagrant.FolderList
	r.Error = json.Unmarshal([]byte(C.GoString(folders)), &f)
	if r.Error != nil {
		return r.Dump()
	}
	var o vagrant.FolderOptions
	r.Error = json.Unmarshal([]byte(C.GoString(opts)), &o)
	if r.Error != nil {
		return r.Dump()
	}
	r.Error = p.SyncedFolder.Prepare(m, f, o)
	return r.Dump()
}

func getSyncedFolderPlugin(pluginName *C.char) (c *plugin.RemoteSyncedFolder, err error) {
	pname := C.GoString(pluginName)
	p, ok := Plugins.SyncedFolders[pname]
	if !ok {
		err = errors.New("Failed to locate requested plugin")
		return
	}
	c = &plugin.RemoteSyncedFolder{
		Client:       p.Client,
		SyncedFolder: p.SyncedFolder}
	return
}
