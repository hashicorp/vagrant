// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package plugin

import (
	"context"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/protobuf/encoding/protojson"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

var (
	// This is the list of components which may be cached
	// locally and re-used when requested
	CacheableComponents = []component.Type{
		component.CommandType,
		component.ConfigType,
		component.HostType,
		component.MapperType,
		component.PluginInfoType,
		component.PushType,
		component.DownloaderType,
	}
)

type PluginRegistration func(hclog.Logger) (*Plugin, error)
type PluginConfigurator func(*Instance, hclog.Logger) error
type PluginInitializer func(*Plugin, hclog.Logger) error

type componentCache map[string]componentEntry
type componentEntry map[component.Type]*Instance

type Manager struct {
	Plugins []*Plugin // Plugins managed by this manager

	builtins        *Builtin             // Buitin plugins when using in process plugins
	builtinsLoaded  bool                 // Flag that builtin plugins are loaded
	cache           cacher.Cache         // Cache used for named plugin requests
	cleaner         cleanup.Cleanup      // Cleanup tasks to perform on closing
	ctx             context.Context      // Context for the manager
	discoveredPaths []path.Path          // List of paths this manager has loaded
	dispenseFuncs   []PluginConfigurator // Configuration functions applied to instances
	instances       componentCache       // Cache for prevlous generated components
	initFuncs       []PluginInitializer  // Initializer functions applied to plugins at creation
	legacyLoaded    bool                 // Flag that legacy plugins have been loaded
	legacyBroker    *plugin.GRPCBroker   // Broker for legacy runtime
	logger          hclog.Logger         // Logger for the manager
	m               sync.Mutex
	rubyC           *serverclient.RubyVagrantClient // Client to the Ruby runtime
	parent          *Manager                        // Parent manager if this is a sub manager
	srv             []byte                          // Marshalled proto message for plugin manager
}

// Create a new plugin manager
func NewManager(
	ctx context.Context, // context for the manager
	r *serverclient.RubyVagrantClient, // client to the ruby runtime
	l hclog.Logger, // logger
) *Manager {
	return &Manager{
		Plugins:       []*Plugin{},
		builtins:      NewBuiltins(ctx, l),
		cache:         cacher.New(),
		cleaner:       cleanup.New(),
		ctx:           ctx,
		dispenseFuncs: []PluginConfigurator{},
		instances:     make(componentCache),
		logger:        l,
		rubyC:         r,
	}
}

// Returns the client to the Ruby runtime
func (m *Manager) RubyClient() *serverclient.RubyVagrantClient {
	if m.parent != nil {
		return m.parent.RubyClient()
	}
	return m.rubyC
}

// Create a sub manager based off current manager
func (m *Manager) Sub(name string) *Manager {
	if name == "" {
		name = "submanager"
	}
	s := &Manager{
		builtinsLoaded:  true,
		cache:           cacher.New(),
		cleaner:         cleanup.New(),
		ctx:             m.ctx,
		discoveredPaths: m.discoveredPaths,
		legacyLoaded:    true,
		instances:       make(componentCache),
		logger:          m.logger.Named(name),
		parent:          m,
	}
	m.closer(func() error { return s.Close() })

	return s
}

// Returns the legacy broker if legacy is enabled. If
// manager is a sub manager, it will request from
// the parent
func (m *Manager) LegacyBroker() *plugin.GRPCBroker {
	if m.legacyBroker != nil {
		return m.legacyBroker
	}

	if m.parent != nil {
		return m.parent.LegacyBroker()
	}

	return nil
}

// Returns true if legacy Vagrant (Ruby runtime) is enabled
func (m *Manager) LegacyEnabled() bool {
	return m.LegacyBroker() != nil
}

// Load legacy Ruby based Vagrant plugins using a
// running Vagrant runtime
func (m *Manager) LoadLegacyPlugins(
	c *serverclient.RubyVagrantClient, // Client connection to the Legacy Ruby Vagrant server
	r plugin.ClientProtocol, // go-plugin client connection to Ruby plugin server
) (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	if m.legacyLoaded {
		m.logger.Warn("ruby based legacy vagrant plugins already loaded, skipping")
		return nil
	}

	m.logger.Trace("loading ruby based legacy vagrant plugins")

	plugins, err := c.GetPlugins()
	if err != nil {
		m.logger.Trace("failed to fetch ruby based legacy vagrant plugin information",
			"error", err,
		)

		return
	}

	for _, p := range plugins {
		m.logger.Info("loading ruby based legacy vagrant plugin",
			"name", p.Name,
			"type", p.Type,
		)

		if err = m.register(RubyFactory(r, p.Name, component.Type(p.Type), p.Options)); err != nil {
			return
		}
	}

	m.legacyLoaded = true
	m.legacyBroker = c.GRPCBroker()

	// Now add a configurator to set the plugin name on plugins
	// when supported
	err = m.Configure(
		func(i *Instance, l hclog.Logger) error {
			s, ok := i.Component.(HasPluginMetadata)
			if !ok {
				l.Warn("plugin does not support name metadata, skipping",
					"component", i.Type.String(),
					"name", i.Name,
				)
				return nil
			}

			s.SetRequestMetadata("plugin_name", i.Name)

			return nil
		},
	)

	return
}

// Load all known builtin plugins
func (m *Manager) LoadBuiltins() (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	if m.builtinsLoaded {
		m.logger.Warn("builing plugins have already been loaded, skipping")
		return nil
	}

	if IN_PROCESS_PLUGINS {
		return m.loadInProcessBuiltins()
	}

	m.logger.Info("loading builtin plugins")
	for name, _ := range Builtins {
		if e := m.register(BuiltinFactory(name)); e != nil {
			err = multierror.Append(err, e)
		}
	}

	m.builtinsLoaded = true

	return
}

// Finds any executable files in provided directory paths and
// registers them as plugins.
func (m *Manager) Discover(
	paths ...path.Path, // List of paths to search for plugins
) error {
	m.m.Lock()
	defer m.m.Unlock()

	for i := 0; i < len(paths); i++ {
		dir := paths[i]
		m.logger.Trace("starting plugin discovery process",
			"path", dir.String())

		for _, p := range m.discoveredPaths {
			if p.String() == dir.String() {
				m.logger.Warn("plugin discovery already processed, skipping",
					"path", dir.String())

				return nil
			}
		}

		files, err := fs.ReadDir(os.DirFS(dir.String()), ".")
		if err != nil {
			m.logger.Warn("failed to read requested directory for discovery, skipping",
				"path", dir.String(),
				"error", err,
			)

			return nil
		}

		for _, entry := range files {
			fullPath := dir.Join(entry.Name())
			i, err := os.Stat(fullPath.String())
			if err != nil {
				m.logger.Error("failed to stat file",
					"path", fullPath,
					"error", err,
				)

				continue
			}

			m.logger.Trace("processing discovered path",
				"path", fullPath,
				"perms", i.Mode().Perm(),
			)

			if entry.Type().IsDir() {
				m.logger.Trace("discovered path is directory, skipping",
					"path", fullPath)

				continue
			}

			if i.Mode().Perm()&0111 == 0 {
				m.logger.Warn("discovered file is not executable, skipping",
					"path", fullPath,
					"perms", i.Mode().Perm(),
				)

				continue
			}

			if runtime.GOOS == "windows" &&
				!strings.HasSuffix(entry.Name(), ".exe") &&
				!strings.HasSuffix(entry.Name(), ".bat") {
				m.logger.Warn("discovered file is not windows executable, skipping",
					"path", fullPath)

				continue
			}

			cmd := exec.Command(fullPath.String())
			if err := m.register(Factory(cmd)); err != nil {
				m.logger.Error("failed to register discovered plugin",
					"path", fullPath,
					"error", err,
				)

				return err
			}
		}
		m.discoveredPaths = append(m.discoveredPaths, dir)
	}

	return nil
}

// Register a new plugin into the manager
func (m *Manager) Register(
	factory PluginRegistration, // Function to generate plugin
) (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	return m.register(factory)
}

// List of plugin configurators that should be applied to instances
func (m *Manager) Configurators() (r []PluginConfigurator) {
	if m.parent != nil {
		r = m.parent.Configurators()
	}
	l := len(r) + len(m.dispenseFuncs)
	rc := make([]PluginConfigurator, l)
	copy(rc, r)
	copy(rc[len(r):l], m.dispenseFuncs)
	r = rc

	return
}

// Add configuration to be applied to plugin instances when requested
func (m *Manager) Configure(fn PluginConfigurator) error {
	m.dispenseFuncs = append(m.dispenseFuncs, fn)
	return nil
}

// Add initializer to be applied to plugin when created
func (m *Manager) Initializer(fn PluginInitializer) error {
	m.initFuncs = append(m.initFuncs, fn)
	return nil
}

// Find a component instance by plugin name and component type
func (m *Manager) Find(
	n string, // Name of the plugin
	t component.Type, // component type of plugin
) (*Instance, error) {
	m.m.Lock()
	defer m.m.Unlock()

	return m.find(n, t)
}

// Get a plugin by name
func (m *Manager) Get(
	n string, // Name of the plugin
	t component.Type, // component type supported by plugin
) (*Plugin, error) {
	for _, p := range m.Plugins {
		if p.Name == n && p.HasType(t) {
			return p, nil
		}
	}

	if m.parent != nil {
		return m.parent.Get(n, t)
	}

	return nil, fmt.Errorf("failed to locate plugin %s implementing component %s", n, t.String())
}

// Find all plugins which support a specific component type
func (m *Manager) Typed(
	t component.Type, // Type of plugins
) ([]string, error) {
	m.logger.Trace("searching for plugins",
		"type", t.String())

	result := []string{}
	for _, p := range m.Plugins {
		if p.HasType(t) {
			result = append(result, p.Name)
			m.logger.Trace("found typed plugin match",
				"type", t.String(),
				"name", p.Name,
			)
		}
	}

	m.logger.Trace("plugin search complete",
		"type", t.String(),
		"count", len(result))

	if m.parent != nil {
		pt, err := m.parent.Typed(t)
		if err != nil {
			return nil, err
		}
		result = append(result, pt...)
	}

	return result, nil
}

// Close the manager (and all managed plugins)
func (m *Manager) Close() (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	m.logger.Info("closing the plugin manager")

	return m.cleaner.Close()
}

// Implements core.PluginManager. Note this returns a slice of core.NamedPlugin
// with only the Type and Name fields populated. To get a NamedPlugin with
// instance of the plugin you need to call GetPlugin.
func (m *Manager) ListPlugins(typeNames ...string) ([]*core.NamedPlugin, error) {
	result := []*core.NamedPlugin{}
	for _, n := range typeNames {
		t, err := component.FindType(n)
		if err != nil {
			return nil, err
		}
		list, err := m.Typed(t)
		if err != nil {
			return nil, err
		}
		for _, p := range list {
			i := &core.NamedPlugin{
				Type:    t.String(),
				Name:    p,
				Options: m.optionsForPlugin(t, p),
			}
			result = append(result, i)
		}
	}
	return result, nil
}

// Implements core.PluginManager
func (m *Manager) GetPlugin(name, typ string) (*core.NamedPlugin, error) {
	t, err := component.FindType(typ)
	if err != nil {
		return nil, err
	}
	cid := t.String() + "-" + name
	if c := m.cache.Get(cid); c != nil {
		return c.(*core.NamedPlugin), nil
	}
	c, err := m.Find(name, t)
	if err != nil {
		return nil, err
	}
	v := &core.NamedPlugin{
		Name:    name,
		Type:    t.String(),
		Plugin:  c.Component,
		Options: c.Options,
	}
	m.cache.Register(cid, v)

	return v, nil
}

// Get (and setup if needed) GRPC server connection information
func (m *Manager) Servinfo() ([]byte, error) {
	if m.srv != nil {
		return m.srv, nil
	}
	if m.LegacyBroker() == nil {
		return nil, fmt.Errorf("legacy broker is unset, cannot create server")
	}

	i := &internal{
		broker:  m.LegacyBroker(),
		cache:   cacher.New(),
		cleanup: m.cleaner,
		logger:  m.logger,
		mappers: []*argmapper.Func{},
	}

	p, err := protomappers.PluginManagerProto(m, m.logger, i)
	if err != nil {
		m.logger.Warn("failed to create plugin manager grpc server",
			"error", err,
		)

		return nil, err
	}

	m.logger.Info("new GRPC server instance started",
		"address", p.Addr,
	)

	m.srv, err = protojson.Marshal(p)

	return m.srv, err
}

// Loads builtin plugins using in process strategy
// instead of isolated processes
func (m *Manager) loadInProcessBuiltins() (err error) {
	f := []PluginRegistration{}
	m.logger.Warn("loading builtin plugins for in process execution")
	for name, opts := range Builtins {
		r, e := m.builtins.Add(name, opts...)
		if e != nil {
			err = multierror.Append(err, e)
			continue
		}
		f = append(f, r)
	}

	if err != nil {
		return
	}

	m.logger.Debug("starting in process builtin plugins")
	m.builtins.Start()

	m.logger.Trace("registering in process builtin plugins")
	for _, b := range f {
		if e := m.Register(b); e != nil {
			err = multierror.Append(err, e)
		}
	}

	return
}

// Registers plugin
// TODO(spox): Need to do a name check and error if
//             name is already in use here or in parent
func (m *Manager) register(
	factory PluginRegistration, // Function to generate plugin
) (err error) {
	plg, err := factory(m.logger.ResetNamed("vagrant.plugin"))
	if err != nil {
		return
	}

	for _, t := range plg.Types {
		m.logger.Info("registering plugin",
			"type", t.String(),
			"name", plg.Name,
		)
	}
	plg.manager = m

	// Run initializers on new plugin
	for _, fn := range m.initFuncs {
		if err = fn(plg, m.logger); err != nil {
			return
		}
	}

	m.Plugins = append(m.Plugins, plg)
	return
}

// Returns an instance of the requested component. If
// the instance has already been found previously, it
// will return a cached value. If it has not previously
// been found, it will be generated and parent loaded
// if applicable. If the component type is allowed to
// be cached, it will be cached locally before being
// returned.
func (m *Manager) find(
	n string, // name of plugin
	t component.Type, // type of component
) (*Instance, error) {
	// Ensure we have a valid entry in the cache map
	if _, ok := m.instances[n]; !ok {
		m.instances[n] = make(componentEntry)
	}

	// If we already have this instance cached, return it
	if i, ok := m.instances[n][t]; ok {
		m.logger.Debug("requested component found in local cache",
			"name", n,
			"type", t.String(),
		)
		return i, nil
	}

	// Try to fetch the instance
	i, err := m.fetch(n, t, nil)

	if err != nil {
		return nil, err
	}

	// Attempt to load the parent if the component has one
	if err := m.loadParent(i); err != nil {
		return nil, err
	}

	// If we got it, store it in the cache and make sure
	// it gets closed when we do
	if m.isCacheable(t) {
		m.instances[n][t] = i
	}

	m.closer(func() error {
		m.logger.Trace("closing plugin instance",
			"name", n,
			"type", t.String(),
		)

		return i.Close()
	})

	return i, nil
}

// This handles fetching a component from this manager or
// the parent manager. It will prepend any PluginConfigurators
// defined on this manager to the list it is provided. The result
// is that components which are generated in a parent will have
// the parent's PluginConfigurators applied first, with the
// child PluginConfigurators applied after.
//
// It should be noted that this only handles generating the instance
// of a component. It does not cache it or load parents.
func (m *Manager) fetch(
	n string, // name of plugin
	t component.Type, // type of component
	c []PluginConfigurator,
) (i *Instance, err error) {
	var cfns []PluginConfigurator
	if len(c) > 0 {
		l := len(c) + len(m.dispenseFuncs)
		cfns = make([]PluginConfigurator, l)
		copy(cfns, m.dispenseFuncs)
		copy(cfns[len(m.dispenseFuncs):l], c)
	} else {
		cfns = m.dispenseFuncs
	}

	// Find the plugin with the matching name and type
	// and generate the component instance
	for _, p := range m.Plugins {
		if p.Name == n && p.HasType(t) {
			return p.instanceOf(t, cfns)
		}
	}

	// If we have a parent, check if we can fetch it
	// from the parent
	if m.parent != nil {
		return m.parent.fetch(n, t, cfns)
	}

	return nil, fmt.Errorf("failed to locate plugin `%s`", n)
}

// Add a cleanup function to be executed when this
// manager is closed
func (m *Manager) closer(f func() error) {
	m.cleaner.Do(f)
}

// Check if component type can be cached
func (m *Manager) isCacheable(t component.Type) bool {
	for _, v := range CacheableComponents {
		if t == v {
			return true
		}
	}
	return false
}

// Check if an instance's component supports having a parent
// and, if so, loading that parent instance and setting it
// into the current instance.
func (m *Manager) loadParent(i *Instance) error {
	c, ok := i.Component.(HasParent)
	if !ok {
		m.logger.Trace("component does not support parents",
			"type", i.Type.String(),
			"name", i.Name,
		)

		return nil
	}

	parentName, err := c.Parent()
	if err != nil {
		m.logger.Error("component parent request failed",
			"type", i.Type.String(),
			"name", i.Name,
			"error", err,
		)

		return err
	}

	// If the parent name is empty, there is no parent
	if parentName == "" {
		return nil
	}

	// Use find() here so the parent instance can be retrieved
	// from the local cache (or can be cached if not yet created).
	pi, err := m.find(parentName, i.Type)
	if err != nil {
		m.logger.Error("failed to find parent component",
			"type", i.Type.String(),
			"name", i.Name,
			"parent_name", parentName,
			"error", err,
		)

		return err
	}

	// Set the parent
	i.Parent = pi
	c.SetParentComponent(pi.Component)

	return nil
}

// optionsForPlugin fetches the options that were registered for a given
// plugin. the return type will be one of component.*Options. If the plugin is
// not found or has no options, returns nil.
func (m *Manager) optionsForPlugin(t component.Type, name string) interface{} {
	for _, p := range m.Plugins {
		if p.Name == name && p.HasType(t) {
			return p.Options[t]
		}
	}

	if m.parent != nil {
		return m.parent.optionsForPlugin(t, name)
	}

	return nil
}
