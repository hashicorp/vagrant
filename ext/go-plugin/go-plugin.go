package main

import (
	"C"
	"io/ioutil"
	"os"

	hclog "github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin"
)

var Plugins *plugin.VagrantPlugin

//export Setup
func Setup(enableLogger, timestamps bool, logLevel *C.char) bool {
	lvl := to_gs(logLevel)
	lopts := &hclog.LoggerOptions{Name: "vagrant"}
	if enableLogger {
		lopts.Output = os.Stderr
	} else {
		lopts.Output = ioutil.Discard
	}
	if !timestamps {
		lopts.TimeFormat = " "
	}
	lopts.Level = hclog.LevelFromString(lvl)
	vagrant.SetDefaultLogger(hclog.New(lopts))

	if Plugins != nil {
		Plugins.Logger.Error("plugins setup failure", "error", "already setup")
		return false
	}

	Plugins = plugin.VagrantPluginInit()
	return true
}

//export LoadPlugins
func LoadPlugins(plgpath *C.char) bool {
	if Plugins == nil {
		vagrant.DefaultLogger().Error("cannot load plugins", "error", "not setup")
		return false
	}

	p := to_gs(plgpath)
	err := Plugins.LoadPlugins(p)
	if err != nil {
		Plugins.Logger.Error("failed loading plugins",
			"path", p, "error", err)
		return false
	}
	Plugins.Logger.Info("plugins successfully loaded", "path", p)
	return true
}

//export Reset
func Reset() {
	if Plugins != nil {
		Plugins.Logger.Info("resetting loaded plugins")
		Teardown()
		dirs := Plugins.PluginDirectories
		Plugins.PluginDirectories = []string{}
		for _, p := range dirs {
			Plugins.LoadPlugins(p)
		}
	} else {
		Plugins.Logger.Warn("plugin reset failure", "error", "not setup")
	}
}

//export Teardown
func Teardown() {
	// only teardown if setup
	if Plugins == nil {
		vagrant.DefaultLogger().Error("cannot teardown plugins", "error", "not setup")
		return
	}
	Plugins.Logger.Debug("tearing down any active plugins")
	Plugins.Kill()
	Plugins.Logger.Info("plugins have been halted")
}

//export ListProviders
func ListProviders() *C.char {
	list := map[string]interface{}{}
	r := &Response{Result: list}
	if Plugins == nil {
		return r.Dump()
	}
	for n, p := range Plugins.Providers {
		info := p.Provider.Info()
		c := p.Client.ReattachConfig()
		data := map[string]interface{}{
			"network":     c.Addr.Network(),
			"address":     c.Addr.String(),
			"description": info.Description,
			"priority":    info.Priority,
		}
		list[n] = data
	}
	r.Result = list
	return r.Dump()
}

//export ListSyncedFolders
func ListSyncedFolders() *C.char {
	list := map[string]interface{}{}
	r := &Response{Result: list}
	if Plugins == nil {
		return r.Dump()
	}
	for n, p := range Plugins.SyncedFolders {
		info := p.SyncedFolder.Info()
		c := p.Client.ReattachConfig()
		data := map[string]interface{}{
			"network":     c.Addr.Network(),
			"address":     c.Addr.String(),
			"description": info.Description,
			"priority":    info.Priority,
		}
		list[n] = data
	}
	r.Result = list
	return r.Dump()
}

// stub required for build
func main() {}

// helper to convert c string to go string
func to_gs(s *C.char) string {
	return C.GoString(s)
}

// helper to convert go string to c string
func to_cs(s string) *C.char {
	return C.CString(s)
}
