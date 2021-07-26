package core

import (
	"context"
	"fmt"
	"strings"
	"sync"

	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
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
	basis    *vagrant_server.Basis
	logger   hclog.Logger
	config   *config.Config
	plugins  *plugin.Manager
	projects map[string]*Project
	mappers  []*argmapper.Func
	dir      *datadir.Basis
	ctx      context.Context

	lock   sync.Mutex
	client *serverclient.VagrantClient

	jobInfo *component.JobInfo
	closers []func() error
	ui      terminal.UI
}

// NewBasis creates a new Basis with the given options.
func NewBasis(ctx context.Context, opts ...BasisOption) (b *Basis, err error) {
	b = &Basis{
		ctx:      ctx,
		logger:   hclog.L(),
		jobInfo:  &component.JobInfo{},
		projects: map[string]*Project{},
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

	// If no UI was provided, initialize a console UI
	if b.ui == nil {
		b.ui = terminal.ConsoleUI(ctx)
	}

	// If the mappers aren't already set, load known mappers
	if len(b.mappers) == 0 {
		b.mappers, err = argmapper.NewFuncList(protomappers.All,
			argmapper.Logger(dynamic.Logger),
		)

		if err != nil {
			return
		}
	}

	// TODO(spox): After fixing up datadir, use that to do
	// configuration loading
	if b.config == nil {
		if b.config, err = config.Load("", ""); err != nil {
			b.logger.Warn("failed to load config, using stub",
				"error", err)
			b.config = &config.Config{}
			err = nil
		}
	}

	// Ensure any modifications to the basis are persisted
	b.Closer(func() error { return b.Save() })

	// Add in our local mappers
	for _, fn := range Mappers {
		f, err := argmapper.NewFunc(fn,
			argmapper.Logger(dynamic.Logger),
		)
		if err != nil {
			return nil, err
		}
		b.mappers = append(b.mappers, f)
	}

	b.logger.Info("basis initialized")
	return
}

// Basis UI is the "default" UI with no prefix modifications
func (b *Basis) UI() (terminal.UI, error) {
	return b.ui, nil
}

// Data directory used for this basis
func (b *Basis) DataDir() (*datadir.Basis, error) {
	return b.dir, nil
}

// Generic function for providing ref to a scope
func (b *Basis) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Basis{
		ResourceId: b.ResourceId(),
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
func (b *Basis) ResourceId() string {
	if b.basis == nil {
		return ""
	}

	return b.basis.ResourceId
}

// Returns the job info if currently set
func (b *Basis) JobInfo() *component.JobInfo {
	return b.jobInfo
}

// Client connection to the Vagrant server
func (b *Basis) Client() *serverclient.VagrantClient {
	return b.client
}

// Returns the detected host for the current platform
func (b *Basis) Host() (host core.Host, err error) {
	hosts, err := b.typeComponents(b.ctx, component.HostType)
	if err != nil {
		return nil, err
	}
	var result core.Host
	var result_name string

	for name, h := range hosts {
		host := h.Value.(core.Host)
		detected, err := host.Detect()
		if err != nil {
			b.logger.Error("host error on detection check",
				"plugin", name,
				"type", "Host",
				"error", err)

			continue
		}
		if result == nil {
			if detected {
				result = host
				result_name = name
			}
			continue
		}

		hp, err := host.Parents()
		if err != nil {
			b.logger.Error("failed to get parents from host",
				"plugin", name,
				"type", "Host",
				"error", err)

			continue
		}

		rp, err := result.Parents()
		if err != nil {
			b.logger.Error("failed to get parents from host",
				"plugin", result_name,
				"type", "Host",
				"error", err)

			continue
		}

		if len(hp) > len(rp) {
			result = host
			result_name = name
		}
	}

	if result == nil {
		return nil, fmt.Errorf("failed to detect host plugin for current platform")
	}

	b.logger.Info("host detection complete",
		"name", result_name)

	return result, nil
}

// Initializes the basis for running a command. This will inspect
// all registered components and extract things like custom command
// information before an actual command is run
func (b *Basis) Init() (result *vagrant_server.Job_InitResult, err error) {
	b.logger.Debug("running init for basis")
	result = &vagrant_server.Job_InitResult{
		Commands: []*vagrant_server.Job_Command{},
	}
	ctx := context.Background()

	cmds, err := b.typeComponents(ctx, component.CommandType)
	if err != nil {
		return nil, err
	}

	for _, c := range cmds {
		fn := c.Value.(component.Command).CommandInfoFunc()
		raw, err := b.callDynamicFunc(ctx, b.logger, fn,
			(*[]*vagrant_server.Job_Command)(nil))

		if err != nil {
			return nil, err
		}

		result.Commands = append(result.Commands,
			raw.([]*vagrant_server.Job_Command)...)
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

	// Set our loaded project into the basis
	b.projects[p.project.ResourceId] = p

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

	// If any targets are defined in the project, load them
	if len(p.project.Targets) > 0 {
		for _, tref := range p.project.Targets {
			p.LoadTarget(WithTargetRef(tref))
		}
	}

	// Ensure any modifications to the project are persisted
	p.Closer(func() error { return p.Save() })

	return
}

// Register functions to be called when closing this basis
func (b *Basis) Closer(c func() error) {
	b.closers = append(b.closers, c)
}

// Close is called to clean up resources allocated by the basis.
// This should be called and blocked on to gracefully stop the basis.
func (b *Basis) Close() (err error) {
	defer b.lock.Unlock()
	b.lock.Lock()

	b.logger.Debug("closing basis",
		"basis", b.ResourceId())

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

	// Call any closers that were registered locally
	for _, c := range b.closers {
		if cerr := c(); cerr != nil {
			b.logger.Warn("error executing closer",
				"error", cerr)
			err = multierror.Append(err, cerr)
		}
	}

	return
}

// Saves the basis to the db
func (b *Basis) Save() (err error) {
	b.logger.Debug("saving basis to db",
		"basis", b.ResourceId())

	_, err = b.Client().UpsertBasis(b.ctx,
		&vagrant_server.UpsertBasisRequest{
			Basis: b.basis})

	if err != nil {
		b.logger.Trace("failed to save basis",
			"basis", b.ResourceId(),
			"error", err)
	}
	return
}

// Saves the basis to the db as well as any projects that have been
// loaded. This will "cascade" to targets as well since `SaveFull` will
// be called on the project.
func (b *Basis) SaveFull() (err error) {
	b.logger.Debug("performing full save",
		"basis", b.ResourceId())

	for _, p := range b.projects {
		b.logger.Trace("saving project",
			"basis", b.ResourceId(),
			"project", p.ResourceId())

		if perr := p.SaveFull(); perr != nil {
			b.logger.Trace("error while saving project",
				"project", p.ResourceId(),
				"error", err)

			err = multierror.Append(err, perr)
		}
	}
	if berr := b.Save(); berr != nil {
		err = multierror.Append(err, berr)
	}
	return
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
		argmapper.Typed(task.CliArgs, b.jobInfo, b.dir))

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
	p, err := b.plugins.ByName(name, typ)
	if err != nil {
		return nil, err
	}
	c, err := p.InstanceOf(typ)
	if err != nil {
		return nil, err
	}

	// TODO(spox): we need to add hooks

	hooks := map[string][]*config.Hook{}
	return &Component{
		Value: c.Component,
		Info: &vagrant_server.Component{
			Type:       vagrant_server.Component_Type(typ),
			Name:       p.Name,
			ServerAddr: b.Client().ServerTarget(),
		},
		hooks:   hooks,
		mappers: b.mappers,
		plugin:  c,
	}, nil
}

// Load all components of a specific type
func (b *Basis) typeComponents(
	ctx context.Context, // context for the plugins,
	typ component.Type, // type of the components,
) (map[string]*Component, error) {
	result := map[string]*Component{}
	plugins, err := b.plugins.ByType(typ)
	if err != nil {
		return nil, err
	}

	for _, p := range plugins {
		c, err := b.component(ctx, typ, p.Name)
		if err != nil {
			return nil, err
		}
		result[p.Name] = c
	}
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

	// add the default arguments always provided by the basis
	args = append(args,
		argmapper.Typed(b, b.ui, ctx, log.Named("plugin-call")),
		argmapper.Named("basis", b),
		argmapper.Logger(dynamic.Logger),
	)

	return dynamic.CallFunc(f, expectedType, b.mappers, args...)
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

func WithBasisConfig(c *config.Config) BasisOption {
	return func(b *Basis) (err error) {
		b.config = c
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
						Path: r.Name,
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
			b.dir, err = datadir.NewBasis(basis.Path)
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
		if !result.Found {
			b.logger.Error("failed to locate basis during setup",
				"resource-id", rid)

			return fmt.Errorf("requested basis is not found (resource-id: %s", rid)
		}
		b.basis = result.Basis
		return
	}
}

var _ core.Basis = (*Basis)(nil)
