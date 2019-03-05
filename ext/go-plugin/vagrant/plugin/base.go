package plugin

import (
	"errors"
	"fmt"
	"os"
	"os/exec"

	hclog "github.com/hashicorp/go-hclog"
	go_plugin "github.com/hashicorp/go-plugin"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

var (
	Handshake = go_plugin.HandshakeConfig{
		MagicCookieKey:   "VAGRANT_PLUGIN_MAGIC_COOKIE",
		MagicCookieValue: "1561a662a76642f98df77ad025aa13a9b16225d93f90475e91090fbe577317ed",
		ProtocolVersion:  1}
)

type RemoteConfig struct {
	Client *go_plugin.Client
	Config vagrant.Config
}

type RemoteProvider struct {
	Client   *go_plugin.Client
	Provider Provider
}

type RemoteGuestCapabilities struct {
	Client            *go_plugin.Client
	GuestCapabilities vagrant.GuestCapabilities
}

type RemoteHostCapabilities struct {
	Client           *go_plugin.Client
	HostCapabilities vagrant.HostCapabilities
}

type RemoteProviderCapabilities struct {
	Client               *go_plugin.Client
	ProviderCapabilities vagrant.ProviderCapabilities
}

type RemoteSyncedFolder struct {
	Client       *go_plugin.Client
	SyncedFolder vagrant.SyncedFolder
}

type VagrantPlugin struct {
	Providers         map[string]*RemoteProvider
	SyncedFolders     map[string]*RemoteSyncedFolder
	PluginDirectories []string
	PluginLookup      func(name, kind string) (p interface{}, err error)
	Logger            hclog.Logger
}

func VagrantPluginInit() *VagrantPlugin {
	v := &VagrantPlugin{
		PluginDirectories: []string{},
		Providers:         map[string]*RemoteProvider{},
		SyncedFolders:     map[string]*RemoteSyncedFolder{},
		Logger:            vagrant.DefaultLogger().Named("go-plugin")}
	v.PluginLookup = v.DefaultPluginLookup
	return v
}

func (v *VagrantPlugin) DefaultPluginLookup(name, kind string) (p interface{}, err error) {
	switch kind {
	case "provider":
		p = v.Providers[name]
	case "synced_folder":
		p = v.SyncedFolders[name]
	default:
		err = errors.New("invalid plugin type")
		return
	}
	if p == nil {
		err = errors.New(fmt.Sprintf("Failed to locate %s plugin of type %s", name, kind))
	}
	return
}

func (v *VagrantPlugin) LoadPlugins(pluginPath string) error {
	for _, p := range v.PluginDirectories {
		if p == pluginPath {
			v.Logger.Error("plugin directory path already loaded", "path", pluginPath)
			return errors.New("plugin directory already loaded")
		}
	}
	v.PluginDirectories = append(v.PluginDirectories, pluginPath)
	if err := v.LoadProviders(pluginPath); err != nil {
		return err
	}
	if err := v.LoadSyncedFolders(pluginPath); err != nil {
		return err
	}
	return nil
}

func (v *VagrantPlugin) LoadProviders(pluginPath string) error {
	providerPaths, err := go_plugin.Discover("*_provider", pluginPath)
	if err != nil {
		v.Logger.Error("error during plugin discovery", "type", "provider",
			"error", err, "path", pluginPath)
		return err
	}
	for _, providerPath := range providerPaths {
		v.Logger.Info("loading provider plugin", "path", providerPath)

		client := go_plugin.NewClient(&go_plugin.ClientConfig{
			AllowedProtocols: []go_plugin.Protocol{go_plugin.ProtocolGRPC},
			Logger:           v.Logger,
			HandshakeConfig:  Handshake,
			Cmd:              exec.Command(providerPath),
			VersionedPlugins: map[int]go_plugin.PluginSet{
				2: {"provider": &ProviderPlugin{}}}})
		gclient, err := client.Client()
		if err != nil {
			v.Logger.Error("error loading provider client", "error", err, "path", providerPath)
			return err
		}
		raw, err := gclient.Dispense("provider")
		if err != nil {
			v.Logger.Error("error loading provider plugin", "error", err, "path", providerPath)
			return err
		}
		prov := raw.(Provider)
		n := prov.Name()
		v.Providers[n] = &RemoteProvider{
			Client:   client,
			Provider: prov}
		v.Logger.Info("plugin loaded", "type", "provider", "name", n, "path", providerPath)
		go v.StreamIO("stdout", prov, n, "provider")
		go v.StreamIO("stderr", prov, n, "provider")
	}
	return nil
}

func (v *VagrantPlugin) LoadSyncedFolders(pluginPath string) error {
	folderPaths, err := go_plugin.Discover("*_synced_folder", pluginPath)
	if err != nil {
		v.Logger.Error("error during plugin discovery", "type", "synced_folder",
			"error", err, "path", pluginPath)
		return err
	}
	for _, folderPath := range folderPaths {
		v.Logger.Info("loading synced_folder plugin", "path", folderPath)

		client := go_plugin.NewClient(&go_plugin.ClientConfig{
			AllowedProtocols: []go_plugin.Protocol{go_plugin.ProtocolGRPC},
			Logger:           v.Logger,
			HandshakeConfig:  Handshake,
			Cmd:              exec.Command(folderPath),
			VersionedPlugins: map[int]go_plugin.PluginSet{
				2: {"synced_folders": &SyncedFolderPlugin{}}}})
		gclient, err := client.Client()
		if err != nil {
			v.Logger.Error("error loading synced_folder client", "error", err, "path", folderPath)
			return err
		}
		raw, err := gclient.Dispense("synced_folder")
		if err != nil {
			v.Logger.Error("error loading synced_folder plugin", "error", err, "path", folderPath)
			return err
		}
		fold := raw.(SyncedFolder)
		n := fold.Name()
		v.SyncedFolders[n] = &RemoteSyncedFolder{
			Client:       client,
			SyncedFolder: fold}
		v.Logger.Info("plugin loaded", "type", "synced_folder", "name", n, "path", folderPath)
		go v.StreamIO("stdout", fold, n, "synced_folder")
		go v.StreamIO("stderr", fold, n, "synced_folder")
	}
	return nil
}

func (v *VagrantPlugin) StreamIO(target string, i vagrant.IOServer, name, kind string) {
	v.Logger.Info("starting plugin IO streaming", "target", target, "plugin", name, "type", kind)
	for {
		str, err := i.Read(target)
		if err != nil {
			v.Logger.Error("plugin IO streaming failure", "target", target, "plugin", name,
				"type", kind, "error", err)
			break
		}
		v.Logger.Debug("received plugin IO content", "target", target, "plugin", name,
			"type", kind, "content", str)
		if target == "stdout" {
			os.Stdout.Write([]byte(str))
		} else if target == "stderr" {
			os.Stderr.Write([]byte(str))
		}
	}
	v.Logger.Info("completed plugin IO streaming", "target", target, "plugin", name, "type", kind)
}

func (v *VagrantPlugin) Kill() {
	v.Logger.Debug("killing all running plugins")
	for n, p := range v.Providers {
		v.Logger.Debug("killing plugin", "name", n, "type", "provider")
		p.Client.Kill()
		v.Logger.Info("plugin killed", "name", n, "type", "provider")
	}
	for n, p := range v.SyncedFolders {
		v.Logger.Debug("killing plugin", "name", n, "type", "synced_folder")
		p.Client.Kill()
		v.Logger.Info("plugin killed", "name", n, "type", "synced_folder")
	}
}
