package core

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"strings"
	"sync"

	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/plugincore"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/factory"
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
	basis     *vagrant_server.Basis
	logger    hclog.Logger
	config    *config.Config
	projects  map[string]*Project
	factories map[component.Type]*factory.Factory
	mappers   []*argmapper.Func
	dir       *datadir.Basis
	ctx       context.Context

	lock   sync.Mutex
	client *serverclient.VagrantClient

	jobInfo *component.JobInfo
	closers []func() error
	ui      terminal.UI
}

// NewBasis creates a new Basis with the given options.
func NewBasis(ctx context.Context, opts ...BasisOption) (b *Basis, err error) {
	b = &Basis{
		ctx:       ctx,
		logger:    hclog.L(),
		jobInfo:   &component.JobInfo{},
		factories: plugin.BaseFactories,
		projects:  map[string]*Project{},
	}

	for _, opt := range opts {
		if oerr := opt(b); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}

	if err != nil {
		return
	}

	if b.basis == nil {
		return nil, errors.New("basis data was not properly loaded")
	}

	// Client is required to be provided
	if b.client == nil {
		return nil, errors.New("client was not provided to basis")
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
			argmapper.Logger(b.logger),
		)
		if err != nil {
			return
		}
	}
	comandArgMapper, _ := argmapper.NewFunc(CommandArgToMap)
	b.mappers = append(b.mappers, comandArgMapper)

	// TODO(spox): After fixing up datadir, use that to do
	// configuration loading
	if b.config == nil {
		if b.config, err = config.Load("", ""); err != nil {
			b.logger.Warn("failed to load config, using stub", "error", err)
			b.config = &config.Config{}
			err = nil
		}
	}

	// Ensure any modifications to the basis are persisted
	b.Closer(func() error { return b.Save() })

	b.logger.Info("basis initialized")
	return
}

func (b *Basis) UI() (terminal.UI, error) {
	return b.ui, nil
}

func (b *Basis) DataDir() (*datadir.Basis, error) {
	return b.dir, nil
}

func (b *Basis) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Basis{
		ResourceId: b.ResourceId(),
		Name:       b.Name(),
	}
}

func (b *Basis) Name() string {
	if b.basis == nil {
		return ""
	}

	return b.basis.Name
}

func (b *Basis) ResourceId() string {
	if b.basis == nil {
		return ""
	}

	return b.basis.ResourceId
}

func (b *Basis) JobInfo() *component.JobInfo {
	return b.jobInfo
}

func (b *Basis) Client() *serverclient.VagrantClient {
	return b.client
}

func (b *Basis) Init() (result *vagrant_server.Job_InitResult, err error) {
	b.logger.Debug("running init for basis")
	f := b.factories[component.CommandType]
	result = &vagrant_server.Job_InitResult{
		Commands: []*vagrant_server.Job_Command{},
	}
	ctx := context.Background()

	for _, name := range f.Registered() {
		var cmd *Component
		cmd, err = b.component(ctx, component.CommandType, name)
		if err != nil {
			return
		}

		if _, err = b.specializeComponent(cmd); err != nil {
			return
		}

		// TODO(spox): Update this to use sdk core interface (against server so manual map required)
		raw, err := b.callDynamicFunc(
			ctx,
			b.logger,
			(interface{})(nil),
			cmd,
			cmd.Value.(component.Command).CommandInfoFunc(),
		)

		if err != nil {
			return nil, err
		}

		r, err := protomappers.CommandInfo(
			raw.(*vagrant_plugin_sdk.Command_CommandInfoResp).CommandInfo)
		if err != nil {
			return nil, err
		}

		result.Commands = append(result.Commands,
			b.convertCommandInfo(r, []string{})...)
	}

	b.logger.Warn("resulting init commands", "commands", result.Commands)
	return
}

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

func (b *Basis) LoadProject(popts ...ProjectOption) (p *Project, err error) {
	// Create our project
	p = &Project{
		ctx:       b.ctx,
		basis:     b,
		logger:    b.logger.Named("project"),
		mappers:   b.mappers,
		factories: b.factories,
		targets:   map[string]*Target{},
		ui:        b.ui,
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

	// Ensure project directory is set
	if p.dir == nil {
		if p.dir, err = b.dir.Project(p.project.Name); err != nil {
			return
		}
	}

	// Ensure any modifications to the project are persisted
	p.Closer(func() error { return p.Save() })

	return
}

func (b *Basis) Closer(c func() error) {
	b.closers = append(b.closers, c)
}

func (b *Basis) Close() (err error) {
	defer b.lock.Unlock()
	b.lock.Lock()

	b.logger.Debug("closing basis", "basis", b.ResourceId())

	// Close down any projects that were loaded
	for name, p := range b.projects {
		b.logger.Trace("closing project", "project", name)
		if cerr := p.Close(); cerr != nil {
			b.logger.Warn("error closing project", "project", name,
				"error", cerr)
			err = multierror.Append(err, cerr)
		}
	}

	// Call any closers that were registered locally
	for _, c := range b.closers {
		if cerr := c(); cerr != nil {
			b.logger.Warn("error executing closer", "error", cerr)
			err = multierror.Append(err, cerr)
		}
	}

	return
}

// Saves the basis to the db
func (b *Basis) Save() (err error) {
	b.logger.Debug("saving basis to db", "basis", b.ResourceId())
	_, err = b.Client().UpsertBasis(b.ctx, &vagrant_server.UpsertBasisRequest{
		Basis: b.basis})
	if err != nil {
		b.logger.Trace("failed to save basis", "basis", b.ResourceId(), "error", err)
	}
	return
}

// Saves the basis to the db as well as any projects that have been loaded
func (b *Basis) SaveFull() (err error) {
	b.logger.Debug("performing full save", "basis", b.ResourceId())
	for _, p := range b.projects {
		b.logger.Trace("saving project", "basis", b.ResourceId(), "project", p.ResourceId())
		if perr := p.SaveFull(); perr != nil {
			b.logger.Trace("error while saving project", "project", p.ResourceId(), "error", err)
			err = multierror.Append(err, perr)
		}
	}
	if berr := b.Save(); berr != nil {
		err = multierror.Append(err, berr)
	}
	return
}

func (b *Basis) Components(ctx context.Context) ([]*Component, error) {
	var results []*Component
	for _, cc := range componentCreatorMap {
		c, err := cc.Create(ctx, b, "")
		if status.Code(err) == codes.Unimplemented {
			c = nil
			err = nil
		}
		if err != nil {
			// Make sure we clean ourselves up in an error case.
			for _, r := range results {
				r.Close()
			}

			return nil, err
		}

		if c != nil {
			results = append(results, c)
		}
	}

	return results, nil
}

func (b *Basis) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	b.logger.Debug("running new task", "basis", b, "task", task)

	// Build the component to run
	cmd, err := b.component(ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	// Specialize it if required
	if _, err = b.specializeComponent(cmd); err != nil {
		return
	}

	// Pass along to the call
	basis := plugincore.NewBasisPlugin(b, b.logger)
	streamId, err := wrapInstance(basis, cmd.plugin.Broker, b)
	bproto := &vagrant_plugin_sdk.Args_Basis{StreamId: streamId}

	// NOTE(spox): Should this be closed after the dynamic func
	// call is complete, or when we tear this down? The latter
	// would allow plugins to keep a persistent connection if
	// multiple things are being run
	b.Closer(func() error {
		if c, ok := basis.(closes); ok {
			return c.Close()
		}
		return nil
	})

	result, err := b.callDynamicFunc(
		ctx,
		b.logger,
		(interface{})(nil),
		cmd,
		cmd.Value.(component.Command).ExecuteFunc(strings.Split(task.CommandName, " ")),
		argmapper.Typed(task.CliArgs),
		argmapper.Typed(bproto),
		argmapper.Named("basis", bproto),
	)
	if err != nil || result == nil || result.(int64) != 0 {
		b.logger.Error("failed to execute command", "type", component.CommandType, "name", task.Component.Name, "error", err)
		return err
	}

	return
}

func (b *Basis) component(ctx context.Context, typ component.Type, name string) (*Component, error) {
	// If this is a command type component, the plugin is registered
	// as only the root command
	if typ == component.CommandType {
		name = strings.Split(name, " ")[0]
	}
	return componentCreatorMap[typ].Create(ctx, b, name)
}

func (b *Basis) specializeComponent(c *Component) (cmp plugin.PluginMetadata, err error) {
	var ok bool
	if cmp, ok = c.Value.(plugin.PluginMetadata); !ok {
		return nil, fmt.Errorf("component does not support specialization")
	}
	cmp.SetRequestMetadata("basis_resource_id", b.ResourceId())
	cmp.SetRequestMetadata("vagrant_service_endpoint", b.client.ServerTarget())

	return
}

func (b *Basis) convertCommandInfo(c *component.CommandInfo, names []string) []*vagrant_server.Job_Command {
	names = append(names, c.Name)
	cmds := []*vagrant_server.Job_Command{
		&vagrant_server.Job_Command{
			Name:     strings.Join(names, " "),
			Synopsis: c.Synopsis,
			Help:     c.Help,
			Flags:    FlagsToProtoMapper(c.Flags),
		},
	}

	for _, scmd := range c.Subcommands {
		cmds = append(cmds, b.convertCommandInfo(scmd, names)...)
	}
	return cmds
}

// startPlugin starts a plugin with the given type and name. The returned
// value must be closed to clean up the plugin properly.
func (b *Basis) startPlugin(
	ctx context.Context,
	typ component.Type,
	n string,
) (*plugin.Instance, error) {
	log := b.logger.Named(strings.ToLower(typ.String()))

	f, ok := b.factories[typ]
	if !ok {
		return nil, fmt.Errorf("unknown factory: %T", typ)
	}

	// Get the factory function for this type
	fn := f.Func(n)
	if fn == nil {
		return nil, fmt.Errorf("unknown type: %q", n)
	}

	// Call the factory to get our raw value (interface{} type)
	fnResult := fn.Call(argmapper.Typed(ctx, log))
	if err := fnResult.Err(); err != nil {
		return nil, err
	}
	log.Info("initialized component", "type", typ.String())
	raw := fnResult.Out(0)

	// If we have a plugin.Instance then we can extract other information
	// from this plugin. We accept pure factories too that don't return
	// this so we type-check here.
	pinst, ok := raw.(*plugin.Instance)
	if !ok {
		pinst = &plugin.Instance{
			Component: raw,
			Close:     func() {},
		}
	}

	return pinst, nil
}

func (b *Basis) callDynamicFunc(
	ctx context.Context,
	log hclog.Logger,
	result interface{}, // expected result type
	c *Component, // component
	f interface{}, // function
	args ...argmapper.Arg,
) (interface{}, error) {
	// We allow f to be a *mapper.Func because our plugin system creates
	// a func directly due to special argument types.
	// TODO: test
	rawFunc, ok := f.(*argmapper.Func)
	if !ok {
		var err error
		rawFunc, err = argmapper.NewFunc(f, argmapper.Logger(log))
		if err != nil {
			return nil, err
		}
	}

	// Be sure that the status is closed after every operation so we don't leak
	// weird output outside the normal execution.
	defer b.ui.Status().Close()

	args = append(args,
		argmapper.ConverterFunc(b.mappers...),
		argmapper.Typed(
			b.jobInfo,
			b.dir,
			b.ui,
		),
	)

	// Make sure we have access to our context and logger and default args
	args = append(args,
		argmapper.Typed(ctx, log),
	)

	// Build the chain and call it
	callResult := rawFunc.Call(args...)
	if err := callResult.Err(); err != nil {
		return nil, err
	}
	raw := callResult.Out(0)

	// If we don't have an expected result type, then just return as-is.
	// Otherwise, we need to verify the result type matches properly.
	if result == nil {
		return raw, nil
	}

	// Verify
	interfaceType := reflect.TypeOf(result).Elem()
	if rawType := reflect.TypeOf(raw); !rawType.Implements(interfaceType) {
		return nil, status.Errorf(codes.FailedPrecondition,
			"operation expected result type %s, got %s",
			interfaceType.String(),
			rawType.String())
	}

	return raw, nil
}

func (b *Basis) execHook(ctx context.Context, log hclog.Logger, h *config.Hook) error {
	return execHook(ctx, b, log, h)
}

func (b *Basis) doOperation(ctx context.Context, log hclog.Logger, op operation) (interface{}, proto.Message, error) {
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

// WithFactory sets a factory for a component type. If this isn't set for
// any component type, then the builtin mapper will be used.
func WithFactory(t component.Type, f *factory.Factory) BasisOption {
	return func(b *Basis) (err error) {
		b.factories[t] = f
		return
	}
}

func WithBasisConfig(c *config.Config) BasisOption {
	return func(b *Basis) (err error) {
		b.config = c
		return
	}
}

// WithComponents sets the factories for components.
func WithComponents(fs map[component.Type]*factory.Factory) BasisOption {
	return func(b *Basis) (err error) {
		b.factories = fs
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

func WithBasisDataDir(dir *datadir.Basis) BasisOption {
	return func(b *Basis) (err error) {
		b.dir = dir
		return
	}
}

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
			b.logger.Error("failed to locate basis during setup", "resource-id", rid)
			return errors.New("requested basis is not found")
		}
		b.basis = result.Basis
		return
	}
}

var _ *Basis = (*Basis)(nil)
