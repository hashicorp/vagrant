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

type PluginRegistration func(hclog.Logger) (*Plugin, error)
type PluginConfigurator func(*Instance, hclog.Logger) error

type Manager struct {
	Plugins []*Plugin // Plugins managed by this manager

	builtins        *Builtin             // Buitin plugins when using in process plugins
	builtinsLoaded  bool                 // Flag that builtin plugins are loaded
	cache           cacher.Cache         // Cache used for named plugin requests
	closers         []func() error       // List of functions to execute on close
	ctx             context.Context      // Context for the manager
	discoveredPaths []path.Path          // List of paths this manager has loaded
	dispenseFuncs   []PluginConfigurator // Configuration functions applied to instances
	legacyLoaded    bool                 // Flag that legacy plugins have been loaded
	legacyBroker    *plugin.GRPCBroker   // Broker for legacy runtime
	logger          hclog.Logger         // Logger for the manager
	m               sync.Mutex
	parent          *Manager // Parent manager if this is a sub manager
	srv             []byte   // Marshalled proto message for plugin manager
}

// Create a new plugin manager
func NewManager(ctx context.Context, l hclog.Logger) *Manager {
	return &Manager{
		Plugins:       []*Plugin{},
		builtins:      NewBuiltins(ctx, l),
		cache:         cacher.New(),
		closers:       []func() error{},
		ctx:           ctx,
		dispenseFuncs: []PluginConfigurator{},
		logger:        l,
	}
}

// Create a sub manager based off current manager
func (m *Manager) Sub(name string) *Manager {
	if name == "" {
		name = "submanager"
	}
	s := &Manager{
		builtinsLoaded:  true,
		cache:           m.cache,
		closers:         []func() error{},
		ctx:             m.ctx,
		discoveredPaths: m.discoveredPaths,
		legacyLoaded:    true,
		logger:          m.logger.Named(name),
		parent:          m,
	}
	m.closer(func() error { return s.Close() })

	return m
}

func (m *Manager) LegacyBroker() *plugin.GRPCBroker {
	return m.legacyBroker
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

		if err = m.register(RubyFactory(r, p.Name, component.Type(p.Type))); err != nil {
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

// Find a specific plugin by name and component type
func (m *Manager) Find(
	n string, // Name of the plugin
	t component.Type, // component type of plugin
) (p *Plugin, err error) {
	for _, p = range m.Plugins {
		if p.Name == n && p.HasType(t) {
			return
		}
	}

	if m.parent != nil {
		return m.parent.Find(n, t)
	}

	return nil, fmt.Errorf("failed to locate plugin `%s`", n)
}

// Find all plugins which support a specific component type
func (m *Manager) Typed(
	t component.Type, // Type of plugins
) ([]*Plugin, error) {
	m.logger.Trace("searching for plugins",
		"type", t.String())

	result := []*Plugin{}
	for _, p := range m.Plugins {
		if p.HasType(t) {
			result = append(result, p)
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

	m.logger.Warn("closing the plugin manager")
	for _, c := range m.closers {
		if e := c(); err != nil {
			err = multierror.Append(err, e)
		}
	}

	for _, p := range m.Plugins {
		if e := p.Close(); e != nil {
			err = multierror.Append(err, e)
		}
	}
	return
}

// Implements core.PluginManager
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
				Type: t.String(),
				Name: p.Name,
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
	p, err := m.Find(name, t)
	if err != nil {
		return nil, err
	}
	c, err := p.InstanceOf(t)
	if err != nil {
		return nil, err
	}
	v := &core.NamedPlugin{
		Name:   p.Name,
		Type:   t.String(),
		Plugin: c.Component,
	}
	m.cache.Register(cid, v)

	return v, nil
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

	m.Plugins = append(m.Plugins, plg)
	return
}

func (m *Manager) closer(f func() error) {
	m.closers = append(m.closers, f)
}

func (m *Manager) Servinfo() ([]byte, error) {
	if m.srv != nil {
		return m.srv, nil
	}
	if m.legacyBroker == nil {
		return nil, fmt.Errorf("legacy broker is unset, cannot create server")
	}

	i := &internal{
		broker:  m.legacyBroker,
		cache:   cacher.New(),
		cleanup: cleanup.New(),
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

	fn := func() error {
		m.logger.Info("closing the plugin manager GRPC server instance")
		return i.cleanup.Close()
	}
	m.closer(fn)

	m.logger.Info("new GRPC server instance started",
		"address", p.Addr,
	)

	m.srv, err = protojson.Marshal(p)

	return m.srv, err
}
