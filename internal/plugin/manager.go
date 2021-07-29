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

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/internal/serverclient"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
)

type PluginRegistration func(hclog.Logger) (*Plugin, error)

type Manager struct {
	Plugins []*Plugin

	builtins        *Builtin
	builtinsLoaded  bool
	legacyLoaded    bool
	discoveredPaths []path.Path
	logger          hclog.Logger
	m               sync.Mutex
}

// Create a new plugin manager
func NewManager(ctx context.Context, l hclog.Logger) *Manager {
	return &Manager{
		Plugins:  []*Plugin{},
		builtins: NewBuiltins(ctx, l),
		logger:   l,
	}
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

	return result, nil
}

// Close the manager (and all managed plugins)
func (m *Manager) Close() (err error) {
	m.m.Lock()
	defer m.m.Unlock()

	for _, p := range m.Plugins {
		if e := p.Close(); e != nil {
			err = multierror.Append(err, e)
		}
	}
	return
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
	plg, err := factory(m.logger)
	if err != nil {
		return
	}

	for _, t := range plg.Types {
		m.logger.Info("registering plugin",
			"type", t.String(),
			"name", plg.Name,
		)
	}

	m.Plugins = append(m.Plugins, plg)
	return
}
