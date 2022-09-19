package core

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/pkg/errors"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
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
	basis         *vagrant_server.Basis       // stored basis data
	boxCollection *BoxCollection              // box collection for this basis
	cache         cacher.Cache                // local basis cache
	cleaner       cleanup.Cleanup             // cleanup tasks to be run on close
	client        *serverclient.VagrantClient // client to vagrant server
	corePlugins   *CoreManager                // manager for the core plugin types
	ctx           context.Context             // local context
	dir           *datadir.Basis              // data directory for basis
	factory       *Factory                    // scope factory
	index         *TargetIndex                // index of targets within basis
	jobInfo       *component.JobInfo          // jobInfo is the base job info for executed functions
	logger        hclog.Logger                // basis specific logger
	mappers       []*argmapper.Func           // mappers for basis
	plugins       *plugin.Manager             // basis scoped plugin manager
	ready         bool                        // flag that instance is ready
	seedValues    *core.Seeds                 // seed values to be applied when running commands
	statebag      core.StateBag               // statebag to persist values
	ui            terminal.UI                 // basis UI (non-prefixed)
	vagrantfile   *Vagrantfile                // vagrantfile instance for basis

	m sync.Mutex
}

// NewBasis creates a new Basis with the given options.
func NewBasis(ctx context.Context, opts ...BasisOption) (*Basis, error) {
	var err error
	b := &Basis{
		basis: &vagrant_server.Basis{
			Configuration: &vagrant_server.Vagrantfile{
				Unfinalized: &vagrant_plugin_sdk.Args_Hash{},
				Format:      vagrant_server.Vagrantfile_RUBY,
			},
		},
		cache:      cacher.New(),
		cleaner:    cleanup.New(),
		ctx:        ctx,
		logger:     hclog.L(),
		mappers:    []*argmapper.Func{},
		jobInfo:    &component.JobInfo{},
		seedValues: core.NewSeeds(),
		statebag:   NewStateBag(),
	}

	for _, opt := range opts {
		if oerr := opt(b); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}

	if err != nil {
		return nil, err
	}

	return b, nil
}

func (b *Basis) Init() error {
	var err error

	// If ready then Init was already run
	if b.ready {
		return nil
	}

	// Client is required to be provided
	if b.client == nil {
		return fmt.Errorf("vagrant server client was not provided to basis")
	}

	// If no plugin manager was provided, force an error
	if b.plugins == nil {
		return fmt.Errorf("plugin manager was not provided to basis")
	}

	// Update our plugin manager to be a sub manager so we close
	// it early if needed
	b.plugins = b.plugins.Sub("basis")

	// Configure our logger
	b.logger = b.logger.ResetNamed("vagrant.core.basis")

	// Attempt to reload the basis to populate our
	// data. If the basis is not found, create it.
	err = b.Reload()
	if err != nil {
		stat, ok := status.FromError(err)
		if !ok || stat.Code() != codes.NotFound {
			return err
		}
		// Project doesn't exist so save it to persist
		if err = b.Save(); err != nil {
			return err
		}
	}

	// If our reloaded data does not include any configuration
	// stub in a default value
	if b.basis.Configuration == nil {
		b.basis.Configuration = &vagrant_server.Vagrantfile{
			Unfinalized: &vagrant_plugin_sdk.Args_Hash{},
			Format:      vagrant_server.Vagrantfile_RUBY,
		}
	}

	// If the basis directory is unset, set it
	if b.dir == nil {
		if b.dir, err = datadir.NewBasis(b.basis.Name); err != nil {
			return err
		}
	}

	// If the mappers aren't already set, load known mappers
	if len(b.mappers) == 0 {
		b.mappers, err = argmapper.NewFuncList(protomappers.All,
			argmapper.Logger(dynamic.Logger),
		)

		if err != nil {
			return err
		}

		locals, err := argmapper.NewFuncList(Mappers, argmapper.Logger(dynamic.Logger))
		if err != nil {
			return err
		}

		b.mappers = append(b.mappers, locals...)
	}

	// Create the manager for handling core plugins
	b.corePlugins = NewCoreManager(b.ctx, b.logger)

	// Setup our index
	b.index = &TargetIndex{
		ctx:    b.ctx,
		logger: b.logger,
		client: b.client,
		basis:  b,
	}

	// If no UI was provided, initialize a console UI
	if b.ui == nil {
		b.ui = terminal.ConsoleUI(b.ctx)
	}

	// Create our vagrantfile
	b.vagrantfile = NewVagrantfile(b.factory, b.boxCollection, b.mappers, b.logger)

	// Register the basis as a Vagrantfile source
	b.vagrantfile.Source(b.basis.Configuration, VAGRANTFILE_BASIS)

	// Register configuration plugins when they are loaded
	b.plugins.Initializer(b.configRegistration)

	// Register any configuration plugins already loaded
	cfgs, err := b.plugins.Typed(component.ConfigType)
	if err != nil {
		return err
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
			return err
		}
		if err = b.configRegistration(p, b.logger); err != nil {
			return err
		}
	}

	// Configure plugins with cache instance
	b.plugins.Configure(b.setPluginCache)

	// Configure plugins to have seeds set
	b.plugins.Configure(b.setPluginSeeds)

	// If we have legacy vagrant loaded, configure managers
	if b.plugins.LegacyEnabled() {
		// Configure plugins to have plugin manager set (used by legacy)
		b.plugins.Configure(b.setPluginManager)

		// Configure plugins to have a core plugin manager set (used by legacy)
		b.plugins.Configure(b.setPluginCoreManager)
	}

	// Load any plugins that may be available
	if err = b.plugins.Discover(b.dir.ConfigDir().Join("plugins")); err != nil {
		b.logger.Error("basis setup failed during plugin discovery",
			"directory", b.dir.ConfigDir().Join("plugins"),
			"error", err,
		)

		return err
	}

	// Set seeds for any plugins that may be used
	b.seed(nil)

	// Initialize the Vagrantfile for the basis
	if err = b.vagrantfile.Init(); err != nil {
		b.logger.Error("basis setup failed to initialize vagrantfile",
			"error", err,
		)
		return err
	}

	// Store our configuration
	sv, err := b.vagrantfile.GetSource(VAGRANTFILE_BASIS)
	if err != nil {
		return err
	}
	b.basis.Configuration = sv

	// Close the plugin manager
	b.Closer(func() error {
		return b.plugins.Close()
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

	// Save ourself when closed
	b.Closer(func() error {
		return b.Save()
	})

	// Mark basis as being initialized
	b.ready = true

	// Include this basis information in log lines
	b.logger = b.logger.With("basis", b)
	b.logger.Info("basis initialized")

	return nil
}

// Provide nice output in logger
func (b *Basis) String() string {
	return fmt.Sprintf("core.Basis:[name: %s resource_id: %s address: %p]",
		b.basis.Name, b.basis.ResourceId, b)
}

// Config implements core.Basis
func (b *Basis) Config() (core.Vagrantfile, error) {
	return b.vagrantfile, nil
}

// CWD implements core.Basis
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

// DefaultProvider implements core.Basis
// This is a subset of the Project.DefaultProvider() algorithm, just the parts
// that make sense when you don't have a Vagrantfile
func (b *Basis) DefaultProvider() (string, error) {
	logger := b.logger.Named("default-provider")
	logger.Debug("Searching for default provider")

	defaultProvider := os.Getenv("VAGRANT_DEFAULT_PROVIDER")
	if defaultProvider != "" {
		logger.Debug("Using VAGRANT_DEFAULT_PROVIDER", "provider", defaultProvider)
		return defaultProvider, nil
	}

	usableProviders := []*core.NamedPlugin{}
	pluginProviders, err := b.plugins.ListPlugins("provider")
	if err != nil {
		return "", err
	}
	for _, pp := range pluginProviders {
		logger.Debug("considering plugin", "provider", pp.Name)

		plug, err := b.plugins.GetPlugin(pp.Name, pp.Type)
		if err != nil {
			return "", err
		}

		plugOpts := plug.Options.(*component.ProviderOptions)
		logger.Debug("got provider options", "options", fmt.Sprintf("%#v", plugOpts))

		// Skip providers that can't be defaulted.
		if !plugOpts.Defaultable {
			logger.Debug("skipping non-defaultable provider", "provider", pp.Name)
			continue
		}

		// Skip the providers that aren't usable.
		logger.Debug("Checking usable on provider", "provider", pp.Name)
		pluginImpl := plug.Plugin.(core.Provider)
		usable, err := pluginImpl.Usable()
		if err != nil {
			return "", err
		}
		if !usable {
			logger.Debug("Skipping unusable provider", "provider", pp.Name)
			continue
		}

		// If we made it here we have a candidate usable provider
		usableProviders = append(usableProviders, plug)
	}
	logger.Debug("Initial usable provider list", "usableProviders", usableProviders)

	// Sort by plugin priority, higher is first
	sort.SliceStable(usableProviders, func(i, j int) bool {
		iPriority := usableProviders[i].Options.(*component.ProviderOptions).Priority
		jPriority := usableProviders[j].Options.(*component.ProviderOptions).Priority
		return iPriority > jPriority
	})
	logger.Debug("Priority sorted usable provider list", "usableProviders", usableProviders)

	preferredProviders := strings.Split(os.Getenv("VAGRANT_PREFERRED_PROVIDERS"), ",")
	k := 0
	for _, pp := range preferredProviders {
		spp := strings.TrimSpace(pp) // .map { s.strip }
		if spp != "" {               // .select { !s.empty? }
			preferredProviders[k] = spp
			k++
		}
	}
	preferredProviders = preferredProviders[:k]

	for _, pp := range preferredProviders {
		for _, up := range usableProviders {
			if pp == up.Name {
				logger.Debug("Using preffered provider found in usable list",
					"provider", pp)
				return pp, nil
			}
		}
	}

	if len(usableProviders) > 0 {
		logger.Debug("Using the first provider from the usable list",
			"provider", usableProviders[0])
		return usableProviders[0].Name, nil
	}

	return "", errors.New("No default provider.")
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
func (b *Basis) RunInit() (result *vagrant_server.Job_InitResult, err error) {
	b.logger.Debug("running init for basis")
	result = &vagrant_server.Job_InitResult{
		Commands: []*vagrant_plugin_sdk.Command_CommandInfo{},
	}
	ctx := context.Background()

	cmds, err := b.typeComponents(ctx, component.CommandType)
	if err != nil {
		return nil, err
	}

	for _, c := range cmds {
		fn := c.Value.(component.Command).CommandInfoFunc()
		// See core.JobCommandProto
		raw, err := b.callDynamicFunc(ctx, b.logger, fn,
			(*[]*vagrant_plugin_sdk.Command_CommandInfo)(nil),
			argmapper.Typed(b.ctx),
		)
		if err != nil {
			return nil, err
		}

		// Primary comes from plugin options so add that to CommandInfo here
		cinfos := raw.([]*vagrant_plugin_sdk.Command_CommandInfo)
		copts := c.Options.(*component.CommandOptions)
		cinfos[0].Primary = copts.Primary

		result.Commands = append(result.Commands, cinfos...)
	}

	return
}

// Register functions to be called when closing this basis
func (b *Basis) Closer(c func() error) {
	b.cleaner.Do(c)
}

// Close is called to clean up resources allocated by the basis.
// This should be called and blocked on to gracefully stop the basis.
func (b *Basis) Close() (err error) {
	b.logger.Debug("closing basis")

	return b.cleaner.Close()
}

// Reload basis data
func (b *Basis) Reload() (err error) {
	b.m.Lock()
	defer b.m.Unlock()

	if b.basis.ResourceId == "" {
		return status.Error(codes.NotFound, "basis does not exist")
	}

	result, err := b.client.FindBasis(b.ctx,
		&vagrant_server.FindBasisRequest{
			Basis: b.basis,
		},
	)

	if err != nil {
		return
	}

	b.basis = result.Basis
	return
}

// Saves the basis to the db
func (b *Basis) Save() (err error) {
	b.m.Lock()
	defer b.m.Unlock()

	b.logger.Debug("saving basis to db")

	if b.vagrantfile != nil {
		val, err := b.vagrantfile.rootToStore()
		if err != nil {
			b.logger.Warn("failed to convert modified configuration for save",
				"error", err,
			)
		} else {
			b.basis.Configuration.Finalized = val.Data
		}
	}

	result, err := b.Client().UpsertBasis(b.ctx,
		&vagrant_server.UpsertBasisRequest{
			Basis: b.basis})

	if err != nil {
		b.logger.Trace("failed to save basis",
			"error", err)
	}

	b.basis = result.Basis
	return
}

func (b *Basis) TargetIndex() (core.TargetIndex, error) {
	return b.index, nil
}

func (b *Basis) Vagrantfile() (core.Vagrantfile, error) {
	return b.vagrantfile, nil
}

// Returns the list of all known components
func (b *Basis) Components(ctx context.Context) ([]*Component, error) {
	return b.components(b.ctx)
}

// Runs a specific task via component which matches the task's
// component name. This is the entry point for running commands.
func (b *Basis) Run(ctx context.Context, task *vagrant_server.Job_CommandOp) (err error) {
	b.logger.Debug("running new command",
		"command", task)

	// Build the component to run
	cmd, err := b.component(ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	fn := cmd.Value.(component.Command).ExecuteFunc(
		strings.Split(task.Command, " "))
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
		Options: c.Options,
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

func (b *Basis) configRegistration(p *plugin.Plugin, l hclog.Logger) error {
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

func (b *Basis) setPluginCache(i *plugin.Instance, l hclog.Logger) error {
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
}

func (b *Basis) setPluginSeeds(i *plugin.Instance, l hclog.Logger) error {
	if s, ok := i.Component.(core.Seeder); ok {
		if err := s.Seed(b.seedValues); err != nil {
			return err
		}
	}
	return nil
}

func (b *Basis) setPluginManager(i *plugin.Instance, l hclog.Logger) error {
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
}

func (b *Basis) setPluginCoreManager(i *plugin.Instance, l hclog.Logger) error {
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
		if r.ResourceId != "" {
			b.basis.ResourceId = r.ResourceId
		}
		if r.Name != "" {
			b.basis.Name = r.Name
		}
		if r.Path != "" {
			b.basis.Path = r.Path
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
var _ Scope = (*Basis)(nil)
