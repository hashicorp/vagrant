// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package core

import (
	"fmt"
	"os/user"
	"reflect"
	"sort"

	"github.com/mitchellh/mapstructure"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/types"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Machine struct {
	*Target
	box         *Box
	machine     *vagrant_server.Target_Machine
	logger      hclog.Logger
	cache       cacher.Cache
	vagrantfile *Vagrantfile
}

func (m *Machine) String() string {
	return fmt.Sprintf("core.Machine[basis: %s, project: %s, resource_id: %s, name: %s, address: %p]",
		m.project.basis.Name(), m.project.Name(), m.target.ResourceId, m.target.Name, m,
	)
}

// Close implements core.Machine
func (m *Machine) Close() (err error) {
	return
}

// ID implements core.Machine
func (m *Machine) ID() (id string, err error) {
	return m.machine.Id, nil
}

// SetID implements core.Machine
func (m *Machine) SetID(value string) (err error) {
	m.machine.Id = value

	// Also set uid
	user, err := user.Current()
	if err != nil {
		return err
	}
	m.machine.Uid = user.Uid

	// Persist changes
	if value == "" {
		m.target.Record = nil
		m.target.State = vagrant_server.Operation_NOT_CREATED
	}

	err = m.SaveMachine()

	return
}

func (m *Machine) Box() (b core.Box, err error) {
	if m.box == nil {
		boxes, _ := m.project.Boxes()
		boxName, err := m.vagrantfile.GetValue("vm", "box")
		if err != nil {
			m.logger.Error("failed to get machine box name from config",
				"error", err,
			)

			return nil, err
		}
		if boxName == nil {
			m.logger.Debug("vagrantfile has no box, so returning nil")
			return nil, nil
		}
		provider, err := m.ProviderName()
		if err != nil {
			return nil, err
		}
		b, err := boxes.Find(boxName.(string), "", provider)
		if err != nil {
			return nil, err
		}
		if b == nil {
			return &Box{
				basis: m.project.basis,
				box: &vagrant_server.Box{
					Name:     boxName.(string),
					Provider: provider,
				},
			}, nil
		}
		m.machine.Box = b.(*Box).ToProto()
		m.SaveMachine()
		m.box = b.(*Box)
	}

	return m.box, nil
}

// Guest implements core.Machine
func (m *Machine) Guest() (g core.Guest, err error) {
	comm, err := m.Communicate()
	if err != nil {
		return nil, err
	}
	isReady, err := comm.Ready(m)
	if err != nil {
		return nil, err
	}
	if !isReady {
		return nil, fmt.Errorf("unable to communicate with guest")
	}
	defer func() {
		if g != nil {
			err = seedPlugin(g, m)
			if err == nil {
				m.cache.Register("guest", g)
			}
		}
	}()

	// Note that if we get the guest value from the
	// local cache, we return it directly to prevent
	// the seeding and cache registration from happening
	// again.
	i := m.cache.Get("guest")
	if i != nil {
		return i.(core.Guest), nil
	}

	// Check if a guest is provided by the Vagrantfile. If it is, then try
	// to use that guest
	vg, err := m.vagrantfile.GetValue("vm", "guest")
	if err != nil {
		m.logger.Trace("failed to get guest value from vagrantfile",
			"error", err,
		)
	} else {
		guestName, ok := vg.(string)
		if ok {
			var guest *Component
			guest, err = m.project.basis.component(m.ctx, component.GuestType, guestName)
			if err != nil {
				return nil, err
			}
			g = guest.Value.(core.Guest)
			return
		} else {
			m.logger.Debug("guest name was not a valid string value",
				"guest", vg,
			)
		}

	}

	// Try to detect a guest
	guests, err := m.project.basis.typeComponents(m.ctx, component.GuestType)
	if err != nil {
		return
	}

	names := make([]string, 0, len(guests))
	pcount := map[string]int{}

	for name, g := range guests {
		names = append(names, name)
		pcount[name] = g.plugin.ParentCount()
	}

	sort.Slice(names, func(i, j int) bool {
		in := names[i]
		jn := names[j]
		// TODO check values exist before use
		return pcount[in] > pcount[jn]
	})

	for _, name := range names {
		guest := guests[name].Value.(core.Guest)
		detected, gerr := guest.Detect(m.toTarget())
		if gerr != nil {
			m.logger.Error("guest error on detection check",
				"plugin", name,
				"type", "Guest",
				"error", err)

			continue
		}
		if detected {
			m.logger.Info("guest detection complete",
				"name", name,
			)
			g = guest
			return
		}
	}

	return nil, fmt.Errorf("failed to detect guest plugin for current platform")
}

func (m *Machine) Inspect() (printable string, err error) {
	name, err := m.Name()
	provider, err := m.Provider()
	printable = "#<" + reflect.TypeOf(m).String() + ": " + name + " (" + reflect.TypeOf(provider).String() + ")>"
	return
}

// ConnectionInfo implements core.Machine
func (m *Machine) ConnectionInfo() (info *core.ConnectionInfo, err error) {
	// TODO: need Vagrantfile
	return
}

// MachineState implements core.Machine
func (m *Machine) MachineState() (state *core.MachineState, err error) {
	p, err := m.Provider()
	if err != nil {
		return nil, err
	}
	m.logger.Info("have machine provider plugin, getting state")
	s, err := p.State()
	m.logger.Info("provider state is returned",
		"state", s,
		"error", err,
	)
	return s, err
}

// SetMachineState implements core.Machine
func (m *Machine) SetMachineState(state *core.MachineState) (err error) {
	var st *vagrant_plugin_sdk.Args_Target_Machine_State
	if err := mapstructure.Decode(state, &st); err != nil {
		return err
	}
	m.machine.State = st

	switch st.Id {
	case "not_created":
		m.target.State = vagrant_server.Operation_NOT_CREATED
	case "running":
		m.target.State = vagrant_server.Operation_CREATED
	case "poweroff":
		m.target.State = vagrant_server.Operation_DESTROYED
	case "pending":
		m.target.State = vagrant_server.Operation_PENDING
	default:
		m.target.State = vagrant_server.Operation_UNKNOWN
	}

	return m.SaveMachine()
}

func (m *Machine) UID() (userId string, err error) {
	return m.machine.Uid, nil
}

func StringToPathFunc() mapstructure.DecodeHookFunc {
	return func(
		f reflect.Type,
		t reflect.Type,
		data interface{}) (interface{}, error) {
		if f.Kind() != reflect.String {
			return data, nil
		}
		if !t.Implements(reflect.TypeOf((*path.Path)(nil)).Elem()) {
			return data, nil
		}

		// Convert it
		return path.NewPath(data.(string)), nil
	}
}

func (m *Machine) defaultSyncedFolderType() (folderType string, err error) {
	logger := m.logger.Named("default-synced-folder-type")

	// Get all available synced folder plugins
	sfPlugins, err := m.project.basis.plugins.ListPlugins("synced_folder")
	if err != nil {
		return
	}

	// Load full plugins so we can read options
	for i, sfp := range sfPlugins {
		fullPlugin, err := m.project.basis.plugins.GetPlugin(sfp.Name, sfp.Type)
		if err != nil {
			logger.Error("error while loading synced folder plugin: name", sfp.Name, "err", err)
			return "", fmt.Errorf("error while loading synced folder plugin: name = %s, err = %s", sfp.Name, err)
		}
		sfPlugins[i] = fullPlugin
	}

	// Sort by plugin priority. Higher is first
	sort.SliceStable(sfPlugins, func(i, j int) bool {
		iPriority := sfPlugins[i].Options.(*component.SyncedFolderOptions).Priority
		jPriority := sfPlugins[j].Options.(*component.SyncedFolderOptions).Priority
		return iPriority > jPriority
	})

	logger.Debug("sorted synced folder plugins", "names", sfPlugins)

	allowedTypesRaw, err := m.vagrantfile.GetValue("vm", "allowed_synced_folder_types")
	if err != nil {
		m.logger.Warn("failed to fetch allowed synced folder types, ignoring",
			"error", err,
		)
		err = nil
	} else {
		allowedTypes, ok := allowedTypesRaw.([]interface{})
		if !ok {
			m.logger.Warn("unexpected type for allowed synced folder types",
				"type", hclog.Fmt("%T", allowedTypesRaw),
			)
		}
		// Remove unallowed types
		if len(allowedTypes) > 0 {
			allowed := make(map[string]struct{})
			for _, a := range allowedTypes {
				typ, err := optionToString(a)
				if err != nil {
					m.logger.Warn("failed to convert synced folder type to string",
						"type", hclog.Fmt("%T", a),
					)
				}
				allowed[typ] = struct{}{}
			}
			k := 0
			for _, sfp := range sfPlugins {
				if _, ok := allowed[sfp.Name]; ok {
					sfPlugins[k] = sfp
					k++
				} else {
					logger.Debug("removing disallowed plugin", "type", sfp.Name)
				}
			}
			sfPlugins = sfPlugins[:k]
		}
	}
	// Check for first usable plugin
	for _, sfp := range sfPlugins {
		syncedFolder := sfp.Plugin.(core.SyncedFolder)
		usable, err := syncedFolder.Usable(m)
		if err != nil {
			logger.Error("error on usable check", "plugin", sfp.Name, "error", err)
			continue
		}
		if usable {
			logger.Info("returning default", "name", sfp.Name)
			return sfp.Name, nil
		} else {
			logger.Debug("skipping unusable plugin", "name", sfp.Name)
		}
	}

	return "", fmt.Errorf("failed to detect guest plugin for current platform")
}

// SyncedFolders implements core.Machine
func (m *Machine) SyncedFolders() (folders []*core.MachineSyncedFolder, err error) {
	syncedFoldersRaw, err := m.vagrantfile.GetValue("vm", "__synced_folders")
	if err != nil {
		m.logger.Error("failed to load synced folders",
			"error", err,
		)

		return
	}
	tmpFolders, ok := syncedFoldersRaw.(map[interface{}]interface{})
	if !ok {
		m.logger.Error("synced folders configuration is unexpected type",
			"type", hclog.Fmt("%T", syncedFoldersRaw),
		)
		return nil, fmt.Errorf("invalid configuration type for synced folders")
	}

	syncedFolders := map[string]map[interface{}]interface{}{}

	for k, v := range tmpFolders {
		var key string
		var ok bool
		if key, ok = k.(string); !ok {
			if skey, ok := k.(types.Symbol); ok {
				key = string(skey)
			} else {
				m.logger.Error("invalid key type for synced folders",
					"key", k,
					"type", hclog.Fmt("%T", k),
				)

				return nil, fmt.Errorf("invalid configuration type for synced folder key")
			}
		}
		value, ok := v.(map[interface{}]interface{})
		if !ok {
			m.logger.Error("invalid value type for synced folders",
				"type", hclog.Fmt("%T", v),
			)
		}

		syncedFolders[key] = value
	}

	for _, options := range syncedFolders {
		var ftype string
		typeRaw, ok := getOptionValue("type", options)
		if ok {
			if ftype, err = optionToString(typeRaw); err != nil {
				m.logger.Debug("failed to convert folder type to string",
					"error", err,
				)

				return
			}
		}
		if ftype == "" {
			ftype, err = m.defaultSyncedFolderType()
			if err != nil {
				return nil, err
			}
		}

		lookup := "syncedfolder_" + ftype
		v := m.cache.Get(lookup)
		if v == nil {
			plg, err := m.project.basis.component(m.ctx, component.SyncedFolderType, ftype)
			if err != nil {
				return nil, err
			}
			v = plg.Value.(core.SyncedFolder)
			m.cache.Register(lookup, v)
		}

		if err = seedPlugin(v, m); err != nil {
			return nil, err
		}

		var guestPath, hostPath path.Path
		guestPathRaw, ok := getOptionValue("guestpath", options)
		if !ok {
			return nil, fmt.Errorf("synced folder options do not include guest path value")
		}
		hostPathRaw, ok := getOptionValue("hostpath", options)
		if !ok {
			return nil, fmt.Errorf("synced folder options do not include host path value")
		}
		if gps, err := optionToString(guestPathRaw); err == nil {
			guestPath = path.NewPath(gps)
		} else {
			return nil, err
		}
		if hps, err := optionToString(hostPathRaw); err == nil {
			hostPath = path.NewPath(hps)
		} else {
			return nil, err
		}

		opts := map[interface{}]interface{}{}
		for k, v := range options {
			key, err := optionToString(k)
			if err != nil {
				return nil, err
			}
			opts[key] = v
		}

		f := &core.Folder{
			Source:      hostPath,
			Destination: guestPath,
			Options:     opts,
		}

		folders = append(folders, &core.MachineSyncedFolder{
			Plugin: v.(core.SyncedFolder),
			Folder: f,
		})
	}
	return
}

func (m *Machine) AsTarget() (core.Target, error) {
	return m.Target, nil
}

func (m *Machine) SaveMachine() (err error) {
	m.logger.Debug("saving machine to db", "machine", m.machine.Id)
	// Update the target record and uuid to match the machine's new state
	// TODO(spox): the uuid shouldn't be getting set to the Id, was there any reason for this?
	// m.target.Uuid = m.machine.Id
	m.target.Record, err = anypb.New(m.machine)
	if err != nil {
		m.logger.Warn("failed to convert machine data to any value",
			"error", err,
		)
		return
	}

	return m.Save()
}

func (m *Machine) toTarget() core.Target {
	return m
}

var _ core.Machine = (*Machine)(nil)
var _ core.Target = (*Machine)(nil)
var _ Scope = (*Machine)(nil)
