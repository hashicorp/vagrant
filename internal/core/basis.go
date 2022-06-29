package core

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	goplugin "github.com/hashicorp/go-plugin"
	"google.golang.org/protobuf/proto"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/dynamic"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// Basis represents the core basis which may
// include one or more projects.
//
// The Close function should be called when
// finished with the basis to properly clean
// up any open resources.
type Basis struct {
	basis         *vagrant_server.Basis
	boxCollection *BoxCollection
	cache         cacher.Cache
	cleaner       cleanup.Cleanup
	corePlugins   *CoreManager
	ctx           context.Context
	client        *serverclient.VagrantClient
	dir           *datadir.Basis
	factory       *Factory
	index         *TargetIndex
	jobInfo       *component.JobInfo
	logger        hclog.Logger
	m             sync.Mutex
	mappers       []*argmapper.Func
	plugins       *plugin.Manager
	projects      map[string]*Project
	seedValues    *core.Seeds
	statebag      core.StateBag
	ui            terminal.UI
	vagrantfile   *Vagrantfile
}

// Cache implements originScope
func (b *Basis) Cache() cacher.Cache {
	return b.cache
}

// Broker implements originScope
func (b *Basis) Broker() *goplugin.GRPCBroker {
	return b.plugins.LegacyBroker()
}

// NewBasis creates a new Basis with the given options.
func NewBasis(ctx context.Context, opts ...BasisOption) (b *Basis, err error) {
	b = &Basis{
		cache:      cacher.New(),
		cleaner:    cleanup.New(),
		ctx:        ctx,
		logger:     hclog.L(),
		jobInfo:    &component.JobInfo{},
		projects:   map[string]*Project{},
		seedValues: core.NewSeeds(),
		statebag:   NewStateBag(),
	}

	for _, opt := range opts {
		if oerr := opt(b); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}

	if err != nil {
		return
	}

	if b.logger.IsTrace() {
		b.logger = b.logger.Named("basis")
	} else {
		b.logger = b.logger.ResetNamed("vagrant.core.basis")
	}

	// Create the manager for handling core plugins
	b.corePlugins = NewCoreManager(ctx, b.logger)

	if b.basis == nil {
		return nil, fmt.Errorf("basis data was not properly loaded")
	}

	// Client is required to be provided
	if b.client == nil {
		return nil, fmt.Errorf("client was not provided to basis")
	}

	// If we don't have a data directory set, lets do that now
	// TODO(spox): actually do that
	if b.dir == nil {
		return nil, fmt.Errorf("WithDataDir must be specified")
	}

	// Setup our index
	b.index = &TargetIndex{
		ctx:    b.ctx,
		logger: b.logger,
		client: b.client,
		basis:  b,
	}

	// If no UI was provided, initialize a console UI
	if b.ui == nil {
		b.ui = terminal.ConsoleUI(ctx)
	}

	// Create our vagrantfile
	b.vagrantfile = NewVagrantfile(b, b.plugins.RubyClient(), b.mappers, b.logger)

	// Register the basis as a Vagrantfile source
	b.vagrantfile.Source(b.basis.Configuration, VAGRANTFILE_BASIS)
	// If the mappers aren't already set, load known mappers
	if len(b.mappers) == 0 {
		b.mappers, err = argmapper.NewFuncList(protomappers.All,
			argmapper.Logger(dynamic.Logger),
		)

		if err != nil {
			return
		}
	}

	// Ensure any modifications to the basis are persisted
	b.Closer(func() error {
		// Update our configuration before we save
		v, err := b.vagrantfile.GetSource(VAGRANTFILE_BASIS)
		if err != nil {
			b.logger.Debug("failed to retrieve vagrantfile configuration",
				"reason", err,
			)
		} else {
			b.basis.Configuration = v
		}
		return b.Save()
	})

	// Close the core manager
	b.Closer(func() error {
		return b.corePlugins.Close()
	})

	// Close the vagrantfile
	b.Closer(func() error {
		return b.vagrantfile.Close()
	})

	// Close the Target Index
	b.Closer(func() error {
		return b.index.Close()
	})

	// Add in local mappers
	for _, fn := range Mappers {
		f, err := argmapper.NewFunc(fn,
			argmapper.Logger(dynamic.Logger),
		)
		if err != nil {
			return nil, err
		}
		b.mappers = append(b.mappers, f)
	}

	// If no plugin manager was provided, force an error
	if b.plugins == nil {
		return nil, fmt.Errorf("no plugin manager provided")
	}

	// Register configuration plugins when they are loaded
	regFn := func(p *plugin.Plugin, l hclog.Logger) error {
		if !p.HasType(component.ConfigType) {
			b.logger.Warn("plugin does not implement config component type",
				"name", p.Name,
			)
			return nil
		}

		b.logger.Debug("registering configuration component",
			"name", p.Name,
		)

		i, err := p.Manager().Find(p.Name, component.ConfigType)
		if err != nil {
			b.logger.Error("failed to load configuration component",
				"name", p.Name,
				"error", err,
			)
			return err
		}

		c, ok := i.Component.(core.Config)
		if !ok {
			return fmt.Errorf("component instance is not valid config: %s", p.Name)
		}
		info, err := c.Register()
		if err != nil {
			b.logger.Error("failed to get registration information from plugin",
				"name", p.Name,
				"error", err,
			)
			return err
		}

		b.logger.Info("registering configuration component",
			"plugin", p.Name,
			"info", *info,
		)
		return b.vagrantfile.Register(info, p)
	}
	b.plugins.Initializer(regFn)

	// Register any configuration plugins already loaded
	cfgs, err := b.plugins.Typed(component.ConfigType)
	if err != nil {
		return nil, err
	}
	for _, cp := range cfgs {
		b.logger.Trace("registering existing config plugin",
			"name", cp,
		)
		p, err := b.plugins.Get(cp, component.ConfigType)
		if err != nil {
			b.logger.Error("failed to get requested plugin",
				"name", cp,
				"error", err,
			)
			return nil, err
		}
		if err = regFn(p, b.logger); err != nil {
			return nil, err
		}
	}

	// Configure plugins with cache instance
	b.plugins.Configure(
		func(i *plugin.Instance, l hclog.Logger) error {
			if c, ok := i.Component.(interface {
				SetCache(cacher.Cache)
			}); ok {
				b.logger.Trace("setting cache on plugin instance",
					"name", i.Name,
					"component", hclog.Fmt("%T", i.Component),
				)
				c.SetCache(b.cache)
			} else {
				b.logger.Warn("cannot set cache on plugin instance",
					"name", i.Name,
					"component", hclog.Fmt("%T", i.Component),
				)
			}

			return nil
		},
	)

	// Configure plugins to have seeds set
	b.plugins.Configure(
		func(i *plugin.Instance, l hclog.Logger) error {
			if s, ok := i.Component.(core.Seeder); ok {
				if err := s.Seed(b.seedValues); err != nil {
					return err
				}
			}
			return nil
		},
	)

	// If we have legacy vagrant loaded, configure managers
	if b.plugins.LegacyEnabled() {
		// Configure plugins to have plugin manager set (used by legacy)
		b.plugins.Configure(
			func(i *plugin.Instance, l hclog.Logger) error {
				s, ok := i.Component.(plugin.HasPluginMetadata)
				if !ok {
					l.Warn("plugin does not support metadata, cannot assign plugin manager",
						"component", i.Type.String(),
						"name", i.Name,
					)

					return nil
				}

				srv, err := b.plugins.Servinfo()
				if err != nil {
					l.Warn("failed to get plugin manager information",
						"error", err,
					)

					return nil
				}
				s.SetRequestMetadata("plugin_manager", string(srv))

				return nil
			},
		)

		// Configure plugins to have a core plugin manager set (used by legacy)
		b.plugins.Configure(
			func(i *plugin.Instance, l hclog.Logger) error {
				s, ok := i.Component.(plugin.HasPluginMetadata)
				if !ok {
					l.Warn("plugin does not support metadata, cannot assign plugin manager",
						"component", i.Type.String(),
						"name", i.Name,
					)

					return nil
				}

				srv, err := b.corePlugins.Servinfo(b.plugins.LegacyBroker())
				if err != nil {
					l.Warn("failed to get plugin manager information",
						"error", err,
					)

					return nil
				}
				s.SetRequestMetadata("core_plugin_manager", string(srv))

				return nil
			},
		)
	}

	if err = b.plugins.Discover(b.dir.ConfigDir().Join("plugins")); err != nil {
		b.logger.Error("basis setup failed during plugin discovery",
			"directory", b.dir.ConfigDir().Join("plugins").String(),
			"error", err,
		)

		return
	}

	// Set seeds for any plugins that may be used
	b.seed(nil)

	// Initialize the Vagrantfile for the basis
	if err = b.vagrantfile.Init(); err != nil {
		b.logger.Error("basis setup failed to initialize vagrantfile",
			"error", err,
		)
		return
	}

	b.logger.Info("basis initialized")
	return
}

func (b *Basis) LoadTarget(topts ...TargetOption) (t *Target, err error) {
	return nil, fmt.Errorf("targets cannot be loaded from a basis")
}

func (b *Basis) String() string {
	return fmt.Sprintf("core.Basis:[name: %s resource_id: %s address: %p]",
		b.basis.Name, b.basis.ResourceId, b)
}

func (b *Basis) Config() (core.Vagrantfile, error) {
	return b.vagrantfile, nil
}

func (p *Basis) CWD() (path path.Path, err error) {
	return paths.VagrantCwd()
}

// Basis UI is the "default" UI with no prefix modifications
func (b *Basis) UI() (terminal.UI, error) {
	return b.ui, nil
}

// Data directory used for this basis
func (b *Basis) DataDir() (*datadir.Basis, error) {
	return b.dir, nil
}

// DefaultPrivateKey implements core.Basis
func (b *Basis) DefaultPrivateKey() (path path.Path, err error) {
	return b.dir.DataDir().Join("insecure_private_key"), nil
}

// Implements core.Basis
// Returns all the registered plugins of the types specified
func (b *Basis) Plugins(types ...string) (plugins []*core.NamedPlugin, err error) {
	plugins = []*core.NamedPlugin{}
	for _, pluginType := range types {
		typ, err := component.FindType(pluginType)
		if err != nil {
			return nil, err
		}
		components, err := b.typeComponents(b.ctx, typ)
		if err != nil {
			return nil, err
		}
		for name, h := range components {
			plugins = append(plugins, &core.NamedPlugin{
				Plugin: h.Value,
				Name:   name,
				Type:   pluginType,
			})
		}
	}
	return
}

// Generic function for providing ref to a scope
func (b *Basis) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Basis{
		ResourceId: b.basis.ResourceId,
		Name:       b.Name(),
	}
}

// Custom name defined for this basis
func (b *Basis) Name() string {
	if b.basis == nil {
		return ""
	}

	return b.basis.Name
}

// Resource ID for this basis
func (b *Basis) ResourceId() (string, error) {
	return b.basis.ResourceId, nil
}

// Returns the job info if currently set
func (b *Basis) JobInfo() *component.JobInfo {
	return b.jobInfo
}

// Client connection to the Vagrant server
func (b *Basis) Client() *serverclient.VagrantClient {
	return b.client
}

func (b *Basis) State() *StateBag {
	return b.statebag.(*StateBag)
}

func (b *Basis) Boxes() (bc core.BoxCollection, err error) {
	if b.boxCollection == nil {
		boxesDir := filepath.Join(b.dir.DataDir().String(), "boxes")
		if _, err := os.Stat(boxesDir); os.IsNotExist(err) {
			err := os.MkdirAll(boxesDir, os.ModePerm)
			if err != nil {
				return nil, err
			}
		}
		b.boxCollection, err = NewBoxCollection(b, boxesDir, b.logger)
		if err != nil {
			return nil, err
		}
	}
	return b.boxCollection, nil
}

// Returns the detected host for the current platform
func (b *Basis) Host() (host core.Host, err error) {
	if h := b.cache.Get("host"); h != nil {
		return h.(core.Host), nil
	}

	rawHostName, err := b.vagrantfile.GetValue("vagrant", "host")
	if err == nil {
		b.logger.Debug("extracted host information from config",
			"host", rawHostName,
		)

		hostName, ok := rawHostName.(string)
		if ok && hostName != "" {
			// If a host is set, then just try to detect that
			hostComponent, err := b.component(b.ctx, component.HostType, hostName)
			if err != nil {
				return nil, fmt.Errorf("failed to find requested host plugin")
			}
			b.cache.Register("host", hostComponent.Value.(core.Host))
			b.logger.Info("host detection overridden by local configuration")
			return hostComponent.Value.(core.Host), nil
		}
	}

	// If a host is not defined in the Vagrantfile, try to detect it
	hosts, err := b.typeComponents(b.ctx, component.HostType)
	if err != nil {
		return nil, err
	}

	var result core.Host
	var result_name string
	var numParents int

	for name, h := range hosts {
		host := h.Value.(core.Host)
		detected, err := host.Detect(b.statebag)
		if err != nil {
			b.logger.Error("host error on detection check",
				"plugin", name,
				"type", "Host",
				"error", err,
			)

			continue
		}
		if result == nil {
			if detected {
				result = host
				result_name = name
				numParents = h.plugin.ParentCount()
			}
			continue
		}

		if detected {
			hp := h.plugin.ParentCount()
			if hp > numParents {
				result = host
				result_name = name
				numParents = hp
			}
		}
	}

	if result == nil {
		return nil, fmt.Errorf("failed to detect host plugin for current platform")
	}

	b.logger.Info("host detection complete",
		"name", result_name)

	b.cache.Register("host", result)

	return result, nil
}

// Initializes the basis for running a command. This will inspect
// all registered components and extract things like custom command
// information before an actual command is run
func (b *Basis) Init() (result *vagrant_server.Job_InitResult, err error) {
	b.logger.Debug("running init for basis")
	list, err := b.plugins.RubyClient().GetCommands()
	if err != nil {
		return nil, err
	}
	existing := map[string]struct{}{}
	for _, i := range list {
		existing[i.Name] = struct{}{}
	}

	result = &vagrant_server.Job_InitResult{
		Commands: list,
	}

	cmds, err := b.plugins.Typed(component.CommandType)
	if err != nil {
		return nil, err
	}

	for _, cmdName := range cmds {
		if _, ok := existing[cmdName]; ok {
			continue
		}
		c, err := b.component(b.ctx, component.CommandType, cmdName)
		if err != nil {
			return nil, err
		}
		fn := c.Value.(component.Command).CommandInfoFunc()
		raw, err := b.callDynamicFunc(b.ctx, b.logger, fn,
			(*[]*vagrant_plugin_sdk.Command_CommandInfo)(nil),
			argmapper.Typed(b.ctx),
		)

		if err != nil {
			return nil, err
		}

		result.Commands = append(result.Commands,
			raw.([]*vagrant_plugin_sdk.Command_CommandInfo)...)
	}

	return
}

// Looks up a project which has already been loaded and is cached
// by the project's name or resource ID. Will return nil if the
// project is not cached.
//
// NOTE: Generally the `LoadProject` function will be preferred
//       as it will return the cached value if previously loaded
//       or load the project if not found.
func (b *Basis) Project(nameOrId string) *Project {
	if p, ok := b.projects[nameOrId]; ok {
		return p
	}
	for _, p := range b.projects {
		if p.project.ResourceId == nameOrId {
			return p
		}
	}
	return nil
}

// Load a project within the current basis. If the project is not found, it
// will be created.
func (b *Basis) LoadProject(popts ...ProjectOption) (p *Project, err error) {
	b.m.Lock()
	defer b.m.Unlock()

	// Create our project
	p = &Project{
		ctx:     b.ctx,
		basis:   b,
		logger:  b.logger,
		mappers: b.mappers,
		targets: map[string]*Target{},
		ui:      b.ui,
	}

	// Apply any options provided
	for _, opt := range popts {
		if oerr := opt(p); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}

	if err != nil {
		return
	}

	// If we already have this project setup, use it instead
	if project := b.Project(p.project.ResourceId); project != nil {
		return project, nil
	}

	if p.logger.IsTrace() {
		p.logger = p.logger.Named("project")
	} else {
		p.logger = p.logger.ResetNamed("vagrant.core.project")
	}

	// Ensure project directory is set
	if p.dir == nil {
		if p.dir, err = b.dir.Project(p.project.Name); err != nil {
			return
		}
	}

	// Load any plugins that may be installed locally to the project
	if err = b.plugins.Discover(path.NewPath(p.project.Path).Join(".vagrant").Join("plugins")); err != nil {
		b.logger.Error("project setup failed during plugin discovery",
			"directory", path.NewPath(p.project.Path).Join(".vagrant").Join("plugins").String(),
			"error", err,
		)
		return nil, err
	}

	// Clone our vagrantfile to use in the new project
	v := b.vagrantfile.clone("project", p)
	p.Closer(func() error { return v.Close() })

	// Add the project vagrantfile
	err = v.Source(p.project.Configuration, VAGRANTFILE_PROJECT)
	if err != nil {
		return nil, err
	}
	// Init the vagrantfile so the config is available
	if err = v.Init(); err != nil {
		return nil, err
	}
	p.vagrantfile = v

	// Ensure any modifications to the project are persisted
	p.Closer(func() error {
		// Save any configuration updates
		v, err := p.vagrantfile.GetSource(VAGRANTFILE_PROJECT)
		if err != nil {
			p.logger.Debug("failed to retrieve vagrantfile",
				"reason", err,
			)
		}
		p.project.Configuration = v
		return p.Save()
	})

	// Remove ourself from cached projects
	p.Closer(func() error {
		b.m.Lock()
		defer b.m.Unlock()
		delete(b.projects, p.project.ResourceId)
		delete(b.projects, p.Name())
		return nil
	})

	// Set seeds for any plugins that may be used
	p.seed(nil)

	// Initialize any targets defined in the project
	if err = p.InitTargets(); err != nil {
		return
	}

	// Set our loaded project into the basis
	b.projects[p.project.ResourceId] = p

	b.logger.Info("done setting up new project instance")

	return
}

// Register functions to be called when closing this basis
func (b *Basis) Closer(c func() error) {
	b.cleaner.Do(c)
}

// Close is called to clean up resources allocated by the basis.
// This should be called and blocked on to gracefully stop the basis.
func (b *Basis) Close() (err error) {
	b.logger.Debug("closing basis",
		"basis", b.basis.ResourceId)

	// Close down any projects that were loaded
	for name, p := range b.projects {
		b.logger.Trace("closing project",
			"project", name)
		if cerr := p.Close(); cerr != nil {
			b.logger.Warn("error closing project",
				"project", name,
				"error", cerr)
			err = multierror.Append(err, cerr)
		}
	}

	if cerr := b.cleaner.Close(); cerr != nil {
		err = multierror.Append(err, cerr)
	}

	return
}

// Saves the basis to the db
func (b *Basis) Save() (err error) {
	b.m.Lock()
	defer b.m.Unlock()

	b.logger.Debug("saving basis to db",
		"basis", b.basis.ResourceId)

	result, err := b.Client().UpsertBasis(b.ctx,
		&vagrant_server.UpsertBasisRequest{
			Basis: b.basis})

	if err != nil {
		b.logger.Trace("failed to save basis",
			"basis", b.basis.ResourceId,
			"error", err)
	}

	b.basis = result.Basis
	return
}

// Saves the basis to the db as well as any projects that have been
// loaded. This will "cascade" to targets as well since `SaveFull` will
// be called on the project.
func (b *Basis) SaveFull() (err error) {
	b.logger.Debug("performing full save",
		"basis", b.basis.ResourceId)

	for _, p := range b.projects {
		b.logger.Trace("saving project",
			"basis", b.basis.ResourceId,
			"project", p.project.ResourceId)

		if perr := p.SaveFull(); perr != nil {
			b.logger.Trace("error while saving project",
				"project", p.project.ResourceId,
				"error", err)

			err = multierror.Append(err, perr)
		}
	}
	if berr := b.Save(); berr != nil {
		err = multierror.Append(err, berr)
	}
	return
}

func (b *Basis) TargetIndex() (core.TargetIndex, error) {
	return b.index, nil
}

// Returns the list of all known components
func (b *Basis) Components(ctx context.Context) ([]*Component, error) {
	return b.components(b.ctx)
}

// Runs a specific task via component which matches the task's
// component name. This is the entry point for running commands.
func (b *Basis) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	b.logger.Debug("running new task",
		"basis", b,
		"task", task)

	// Build the component to run
	cmd, err := b.component(ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	fn := cmd.Value.(component.Command).ExecuteFunc(
		strings.Split(task.CommandName, " "))
	result, err := b.callDynamicFunc(ctx, b.logger, fn, (*int32)(nil),
		argmapper.Typed(task.CliArgs, b.jobInfo, b.dir, b.ctx, b.ui),
		argmapper.ConverterFunc(cmd.mappers...),
	)

	if err != nil || result == nil || result.(int32) != 0 {
		b.logger.Error("failed to execute command",
			"type", component.CommandType,
			"name", task.Component.Name,
			"error", err)

		cmdErr := &runError{}
		if err != nil {
			cmdErr.err = err
		}
		if result != nil {
			cmdErr.exitCode = result.(int32)
		}

		return cmdErr
	}

	return
}

// Load a specific component
func (b *Basis) component(
	ctx context.Context, // context for the plugin
	typ component.Type, // type of component
	name string, // name of the component
) (*Component, error) {
	// If this is a command type component, the plugin is registered
	// as only the root command
	if typ == component.CommandType {
		name = strings.Split(name, " ")[0]
	}
	c, err := b.plugins.Find(name, typ)
	if err != nil {
		return nil, err
	}

	// TODO(spox): we need to add hooks

	hooks := map[string][]*config.Hook{}
	return &Component{
		Value: c.Component,
		Info: &vagrant_server.Component{
			Type:       vagrant_server.Component_Type(typ),
			Name:       name,
			ServerAddr: b.Client().ServerTarget(),
		},
		hooks:   hooks,
		mappers: append(b.mappers, c.Mappers...),
		plugin:  c,
	}, nil
}

// Load all components of a specific type
func (b *Basis) typeComponents(
	ctx context.Context, // context for the plugins,
	typ component.Type, // type of the components,
) (map[string]*Component, error) {
	result := map[string]*Component{}
	plugins, err := b.plugins.Typed(typ)
	if err != nil {
		return nil, err
	}

	b.logger.Info("fetching all typed plugins",
		"type", typ.String(),
	)
	for _, p := range plugins {
		b.logger.Info("fetching typed component",
			"plugin", p,
			"type", typ.String(),
		)
		c, err := b.component(ctx, typ, p)
		if err != nil {
			b.logger.Error("failed to fetch component",
				"plugin", p,
				"type", typ.String(),
			)
			return nil, err
		}
		result[p] = c
	}
	b.logger.Info("fetched all typed plugins",
		"type", typ.String(),
		"count", len(result),
	)
	return result, nil
}

// Load all components
func (b *Basis) components(
	ctx context.Context, // context for the plugins
) ([]*Component, error) {
	result := []*Component{}

	for _, p := range b.plugins.Plugins {
		for _, t := range p.Types {
			c, err := b.component(ctx, t, p.Name)
			if err != nil {
				return nil, err
			}
			result = append(result, c)
		}
	}
	return result, nil
}

// Calls the function provided and converts the
// result to an expected type. If no type conversion
// is required, a `false` value for the expectedType
// will return the raw interface return value.
//
// By default, the basis, provided context, and basis
// UI are added as a typed arguments. The basis is
// also added as a named argument.
func (b *Basis) callDynamicFunc(
	ctx context.Context, // context for function execution
	log hclog.Logger, // logger to provide function execution
	f interface{}, // function to call
	expectedType interface{}, // nil pointer of expected return type
	args ...argmapper.Arg, // list of argmapper arguments
) (interface{}, error) {
	// ensure our UI status is closed after every call since this is
	// the UI we send by default
	defer b.ui.Status().Close()

	// Add seed arguments
	for _, v := range b.seedValues.Typed {
		b.logger.Trace("seeding typed value into dynamic call",
			"fn", hclog.Fmt("%p", f),
			"value", hclog.Fmt("%T", v),
		)

		args = append(args, argmapper.Typed(v))
	}

	for k, v := range b.seedValues.Named {
		b.logger.Trace("seeding named value into dynamic call",
			"fn", hclog.Fmt("%p", f),
			"name", k,
			"value", hclog.Fmt("%T", v),
		)

		args = append(args, argmapper.Named(k, v))
	}

	// Always include a logger within our arguments
	args = append(args, argmapper.Typed(b.logger))
	return dynamic.CallFunc(f, expectedType, b.mappers, args...)
}

func (b *Basis) seed(fn func(*core.Seeds)) {
	s := b.seedValues
	s.AddNamed("basis", b)
	s.AddNamed("basis_ui", b.ui)
	s.AddTyped(b, b.ui, b.corePlugins)
	if fn != nil {
		fn(s)
	}
}

func (b *Basis) execHook(
	ctx context.Context,
	log hclog.Logger,
	h *config.Hook,
) error {
	return execHook(ctx, b, log, h)
}

func (b *Basis) doOperation(
	ctx context.Context,
	log hclog.Logger,
	op operation,
) (interface{}, proto.Message, error) {
	return doOperation(ctx, log, b, op)
}

// BasisOption is used to set options for NewBasis.
type BasisOption func(*Basis) error

// WithClient sets the API client to use.
func WithClient(client *serverclient.VagrantClient) BasisOption {
	return func(b *Basis) (err error) {
		b.client = client
		return
	}
}

// WithLogger sets the logger to use with the project. If this option
// is not provided, a default logger will be used (`hclog.L()`).
func WithLogger(log hclog.Logger) BasisOption {
	return func(b *Basis) (err error) {
		b.logger = log
		return
	}
}

func WithPluginManager(m *plugin.Manager) BasisOption {
	return func(b *Basis) (err error) {
		b.plugins = m
		return
	}
}

// WithMappers adds the mappers to the list of mappers.
func WithMappers(m ...*argmapper.Func) BasisOption {
	return func(b *Basis) (err error) {
		b.mappers = append(b.mappers, m...)
		return
	}
}

// WithUI sets the UI to use. If this isn't set, a BasicUI is used.
func WithUI(ui terminal.UI) BasisOption {
	return func(b *Basis) (err error) {
		b.ui = ui
		return
	}
}

// WithJobInfo sets the base job info used for any executed operations.
func WithJobInfo(info *component.JobInfo) BasisOption {
	return func(b *Basis) (err error) {
		b.jobInfo = info
		return
	}
}

// WithBasisDataDir customizes the datadir for the Basis
func WithBasisDataDir(dir *datadir.Basis) BasisOption {
	return func(b *Basis) (err error) {
		b.dir = dir
		return
	}
}

// WithBasisRef is used to load or initialize the basis
func WithBasisRef(r *vagrant_plugin_sdk.Ref_Basis) BasisOption {
	return func(b *Basis) (err error) {
		var basis *vagrant_server.Basis
		// if we don't have a resource ID we need to upsert
		if r.ResourceId == "" {
			var result *vagrant_server.UpsertBasisResponse
			result, err = b.client.UpsertBasis(
				context.Background(),
				&vagrant_server.UpsertBasisRequest{
					Basis: &vagrant_server.Basis{
						Name: r.Name,
					},
				},
			)
			if err != nil {
				return
			}
			basis = result.Basis
		} else {
			var result *vagrant_server.GetBasisResponse
			result, err = b.client.GetBasis(
				context.Background(),
				&vagrant_server.GetBasisRequest{
					Basis: r,
				},
			)
			if err != nil {
				return
			}
			basis = result.Basis
		}
		b.basis = basis
		// if the datadir isn't set, do that now
		if b.dir == nil {
			b.dir, err = datadir.NewBasis(basis.Name)
			if err != nil {
				return
			}
		}
		return
	}
}

func WithBasisResourceId(rid string) BasisOption {
	return func(b *Basis) (err error) {
		result, err := b.client.FindBasis(b.ctx, &vagrant_server.FindBasisRequest{
			Basis: &vagrant_server.Basis{
				ResourceId: rid,
			},
		})
		if err != nil {
			return
		}
		if result == nil {
			b.logger.Error("failed to locate basis during setup",
				"resource-id", rid)

			return fmt.Errorf("requested basis is not found (resource-id: %s", rid)
		}
		b.basis = result.Basis
		return
	}
}

func WithFactory(f *Factory) BasisOption {
	return func(b *Basis) (err error) {
		b.factory = f
		return
	}
}

func FromBasis(basis *Basis) BasisOption {
	return func(b *Basis) (err error) {
		b.logger = basis.logger
		b.plugins = basis.plugins // TODO(spox): we need stacked managers
		b.ctx = basis.ctx
		b.client = basis.client
		b.ui = basis.ui
		return
	}
}

var _ core.Basis = (*Basis)(nil)
