package core

import (
	"context"
	"fmt"
	"reflect"
	"strings"
	"sync"

	"github.com/DavidGamba/go-getoptions/option"
	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"github.com/mitchellh/mapstructure"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
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
	name       string
	resourceid string
	logger     hclog.Logger
	config     *config.Config
	projects   map[string]*Project
	factories  map[component.Type]*factory.Factory
	mappers    []*argmapper.Func
	dir        *datadir.Basis
	env        *Environment

	labels         map[string]string
	overrideLabels map[string]string

	client *serverclient.VagrantClient

	jobInfo *component.JobInfo
	lock    sync.Mutex
	closers []func() error
	UI      terminal.UI
}

func (b *Basis) Ui() terminal.UI {
	return b.UI
}

func (b *Basis) Ref() interface{} {
	return &vagrant_server.Ref_Basis{
		ResourceId: b.resourceid,
		Name:       b.name,
	}
}

func (b *Basis) JobInfo() *component.JobInfo {
	return b.jobInfo
}

func (b *Basis) Client() *serverclient.VagrantClient {
	return b.client
}

func (b *Basis) Environment() *Environment {
	return b.env
}

func (b *Basis) Init() (result *vagrant_server.Job_InitResult, err error) {
	b.logger.Trace("running init for basis")
	f := b.factories[component.CommandType]
	result = &vagrant_server.Job_InitResult{}
	for _, name := range f.Registered() {
		if name != "myplugin" {
			continue
		}
		c, err := componentCreatorMap[component.CommandType].Create(context.Background(), b, name)
		if err != nil {
			b.logger.Error("failed to start plugin", "name", name, "error", err)
			continue
		}
		cmd, ok := c.Value.(sdkcore.Command)
		if !ok {
			b.logger.Error("failed to convert to command component")
			continue
		}
		b.logger.Trace("started a new plugin for init", "name", name)
		cmdInfo, err := cmd.CommandInfo()
		if err != nil {
			b.logger.Error("failed to get command info for command "+name, "error", err)
		}
		names := []string{cmdInfo.Name}
		err = RegisterSubcommands(cmdInfo, names, result)
		if err != nil {
			b.logger.Error("subcommand error", err)
		}
		result.Commands = append(
			result.Commands,
			&vagrant_server.Job_Command{
				Name:     name,
				Synopsis: cmdInfo.Synopsis,
				Help:     cmdInfo.Help,
				Flags:    FlagsToProtoMapper(cmdInfo.Flags),
			},
		)
	}

	return
}

func RegisterSubcommands(cmd *sdkcore.CommandInfo, names []string, result *vagrant_server.Job_InitResult) (err error) {
	subcmds := cmd.Subcommands
	if len(subcmds) > 0 {
		for _, scmd := range subcmds {
			name := append(names, scmd.Name)
			result.Commands = append(
				result.Commands,
				&vagrant_server.Job_Command{
					Name:     strings.Join(name, " "),
					Synopsis: scmd.Synopsis,
					Help:     scmd.Help,
					Flags:    FlagsToProtoMapper(scmd.Flags),
				},
			)
			err = RegisterSubcommands(scmd, name, result)
		}
	}
	return
}

func FlagsToProtoMapper(input []*option.Option) []*vagrant_server.Job_Flag {
	output := []*vagrant_server.Job_Flag{}

	for _, f := range input {
		var flagType vagrant_server.Job_Flag_Type
		switch f.OptType {
		case option.StringType:
			flagType = vagrant_server.Job_Flag_STRING
		case option.BoolType:
			flagType = vagrant_server.Job_Flag_BOOL
		}

		// TODO: get aliases
		j := &vagrant_server.Job_Flag{
			LongName:     f.Name,
			ShortName:    f.Name,
			Description:  f.Description,
			DefaultValue: f.DefaultStr,
			Type:         flagType,
		}
		output = append(output, j)
	}
	return output
}

func ProtoToFlagsMapper(input []*vagrant_server.Job_Flag) (opt []*option.Option, err error) {
	opt = []*option.Option{}
	for _, f := range input {
		var newOpt *option.Option
		switch f.Type {
		case vagrant_server.Job_Flag_STRING:
			newOpt = option.New(f.LongName, option.StringType)
		case vagrant_server.Job_Flag_BOOL:
			newOpt = option.New(f.LongName, option.BoolType)
		}
		newOpt.Description = f.Description
		newOpt.DefaultStr = f.DefaultValue
		opt = append(opt, newOpt)
	}
	return opt, err
}

// NewBasis creates a new Basis with the given options.
func NewBasis(ctx context.Context, opts ...BasisOption) (b *Basis, err error) {
	b = &Basis{
		logger:    hclog.L(),
		jobInfo:   &component.JobInfo{},
		factories: plugin.BaseFactories,
	}

	for _, opt := range opts {
		opt(b)
	}

	// If we don't have a data directory set, lets do that now
	if b.dir == nil {
		return nil, fmt.Errorf("WithDataDir must be specified")
	}

	if b.UI == nil {
		b.UI = terminal.ConsoleUI(ctx)
	}

	if len(b.mappers) == 0 {
		b.mappers, err = argmapper.NewFuncList(protomappers.All,
			argmapper.Logger(b.logger),
		)
		if err != nil {
			return
		}
	}

	envMapper, _ := argmapper.NewFunc(EnvironmentProto)
	b.mappers = append(b.mappers, envMapper)

	if b.client == nil {
		panic("b.client should never be nil")
	}

	if b.config == nil {
		b.config, err = config.Load("", "")
	}

	b.env, err = NewEnvironment(ctx,
		WithHomePath(b.dir.Dir.RootDir()),
		WithServerAddr(b.client.ServerTarget()),
	)
	if err != nil {
		return nil, err
	}

	b.logger.Info("basis initialized")
	return
}

// TODO: put this in a better place
func EnvironmentProto(input *Environment) (*vagrant_plugin_sdk.Args_Project, error) {
	var result vagrant_plugin_sdk.Args_Project
	pathToStringHook := func(f, t reflect.Type, data interface{}) (interface{}, error) {
		if f != reflect.TypeOf(path.NewPath(".")) {
			return data, nil
		}

		if t.Kind() != reflect.String {
			return data, nil
		}

		// Convert it
		path := data.(path.Path)
		return path.String(), nil
	}

	decoder, err := mapstructure.NewDecoder(
		&mapstructure.DecoderConfig{
			DecodeHook: pathToStringHook,
			Metadata:   nil,
			Result:     &result,
		},
	)
	if err != nil {
		return nil, err
	}
	return &result, decoder.Decode(input)
}

func (b *Basis) LoadProject(ctx context.Context, popts ...ProjectOption) (p *Project, err error) {
	// Create our project
	p = &Project{
		basis:     b,
		logger:    b.logger.Named("project"),
		mappers:   b.mappers,
		factories: b.factories,
		machines:  map[string]*Machine{},
		UI:        b.UI,
		env:       b.env,
	}
	var opts options

	// Apply any options provided
	for _, opt := range popts {
		opt(p, &opts)
	}

	// Ensure project directory is set
	if p.dir == nil {
		return nil, fmt.Errorf("WithProjectDataDir must be specified")
	}

	// Validate the configuration
	if err = opts.Config.Validate(); err != nil {
		return
	}

	// Validate the labels
	if errs := config.ValidateLabels(p.overrideLabels); len(errs) > 0 {
		return nil, multierror.Append(nil, errs...)
	}

	p.labels = opts.Config.Labels

	for _, mCfg := range opts.Config.Machines {
		var d *datadir.Machine
		if d, err = p.dir.Machine(mCfg.Name); err != nil {
			return
		}

		m := &Machine{
			name:   mCfg.Name,
			config: mCfg,
			logger: p.logger.Named(mCfg.Name),
			dir:    d,
			UI:     terminal.ConsoleUI(ctx),
		}

		p.machines[m.name] = m
	}

	return
}

func (b *Basis) Close() error {
	for _, c := range b.closers {
		c()
	}

	return nil
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

func (b *Basis) component(ctx context.Context, typ component.Type, name string) (*Component, error) {
	return componentCreatorMap[typ].Create(ctx, b, name)
}

func (b *Basis) specializeComponent(c *Component) (cmp plugin.PluginMetadata, err error) {
	var ok bool
	if cmp, ok = c.Value.(plugin.PluginMetadata); !ok {
		return nil, fmt.Errorf("component does not support specialization")
	}
	cmp.SetRequestMetadata("basis_resource_id", b.resourceid)
	cmp.SetRequestMetadata("vagrant_service_endpoint", b.client.ServerTarget())

	return
}

func (b *Basis) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	b.logger.Debug("running new task", "basis", b, "task", task)

	cmd, err := b.component(ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	if _, err = b.specializeComponent(cmd); err != nil {
		return
	}

	result, err := b.callDynamicFunc(
		ctx,
		b.logger,
		(interface{})(nil),
		cmd,
		cmd.Value.(component.Command).ExecuteFunc(),
		argmapper.Typed(task.CliArgs),
	)
	if err != nil || result == nil || result.(int64) != 0 {
		b.logger.Error("failed to execute command", "type", component.CommandType, "name", task.Component.Name, "error", err)
		return err
	}

	return
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
	defer b.UI.Status().Close()

	args = append(args,
		argmapper.ConverterFunc(b.mappers...),
		argmapper.Typed(
			b.jobInfo,
			b.dir,
			b.UI,
		),
	)

	// Make sure we have access to our context and logger and default args
	args = append(args,
		argmapper.Typed(ctx, log),
		argmapper.Named("labels", &component.LabelSet{Labels: c.labels}),
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

func (b *Basis) mergeLabels(ls ...map[string]string) map[string]string {
	result := map[string]string{}

	// Merge order
	mergeOrder := []map[string]string{result, b.labels}
	mergeOrder = append(mergeOrder, ls...)
	mergeOrder = append(mergeOrder, b.overrideLabels)

	// Merge them
	return labelsMerge(mergeOrder...)
}

func (b *Basis) execHook(ctx context.Context, log hclog.Logger, h *config.Hook) error {
	return execHook(ctx, b, log, h)
}

func (b *Basis) doOperation(ctx context.Context, log hclog.Logger, op operation) (interface{}, proto.Message, error) {
	return doOperation(ctx, log, b, op)
}

// BasisOption is used to set options for NewBasis.
type BasisOption func(*Basis)

// WithClient sets the API client to use.
func WithClient(client *serverclient.VagrantClient) BasisOption {
	return func(b *Basis) {
		b.client = client
	}
}

// WithLogger sets the logger to use with the project. If this option
// is not provided, a default logger will be used (`hclog.L()`).
func WithLogger(log hclog.Logger) BasisOption {
	return func(b *Basis) { b.logger = log }
}

// WithFactory sets a factory for a component type. If this isn't set for
// any component type, then the builtin mapper will be used.
func WithFactory(t component.Type, f *factory.Factory) BasisOption {
	return func(b *Basis) { b.factories[t] = f }
}

func WithBasisConfig(c *config.Config) BasisOption {
	return func(b *Basis) { b.config = c }
}

// WithComponents sets the factories for components.
func WithComponents(fs map[component.Type]*factory.Factory) BasisOption {
	return func(b *Basis) { b.factories = fs }
}

// WithMappers adds the mappers to the list of mappers.
func WithMappers(m ...*argmapper.Func) BasisOption {
	return func(b *Basis) { b.mappers = append(b.mappers, m...) }
}

// WithUI sets the UI to use. If this isn't set, a BasicUI is used.
func WithUI(ui terminal.UI) BasisOption {
	return func(b *Basis) { b.UI = ui }
}

// WithJobInfo sets the base job info used for any executed operations.
func WithJobInfo(info *component.JobInfo) BasisOption {
	return func(b *Basis) { b.jobInfo = info }
}

func WithBasisDataDir(dir *datadir.Basis) BasisOption {
	return func(b *Basis) { b.dir = dir }
}

func WithBasisRef(r *vagrant_server.Ref_Basis) BasisOption {
	return func(b *Basis) {
		var basis *vagrant_server.Basis
		// if we don't have a resource ID we need to upsert
		if r.ResourceId == "" {
			result, err := b.client.UpsertBasis(
				context.Background(),
				&vagrant_server.UpsertBasisRequest{
					Basis: &vagrant_server.Basis{
						Name: r.Name,
						Path: r.Name,
					},
				},
			)
			if err != nil {
				panic("failed to upsert basis") // TODO(spox): don't panic
			}
			basis = result.Basis
		} else {
			result, err := b.client.GetBasis(
				context.Background(),
				&vagrant_server.GetBasisRequest{
					Basis: r,
				},
			)
			if err != nil {
				panic("failed to retrieve basis") // TODO(spox): don't panic
			}
			basis = result.Basis
		}
		b.name = basis.Name
		b.resourceid = basis.ResourceId
		// if the datadir isn't set, do that now
		if b.dir == nil {
			var err error
			b.dir, err = datadir.NewBasis(basis.Path)
			if err != nil {
				panic("failed to setup basis datadir") // TODO(spox): don't panic
			}
		}
	}
}

var _ *Basis = (*Basis)(nil)
