package core

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"time"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	goplugin "github.com/hashicorp/go-plugin"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/dynamic"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type Target struct {
	ctx     context.Context
	target  *vagrant_server.Target
	project *Project
	logger  hclog.Logger
	dir     *datadir.Target

	m           sync.Mutex
	jobInfo     *component.JobInfo
	closers     []func() error
	ui          terminal.UI
	cache       cacher.Cache
	vagrantfile *Vagrantfile
}

func (t *Target) String() string {
	return fmt.Sprintf("core.Target[basis: %s, project: %s, resource_id: %s, address: %p]",
		t.project.basis.Name(), t.project.Name(), t.target.ResourceId, t,
	)
}

func (t *Target) Config() (c interface{}, err error) {
	//	err = vconfig.DecodeConfiguration(b.target.Configuration.Serialized, c)
	return nil, fmt.Errorf("not implemented")
}

func (t *Target) GetUUID() (id string, err error) {
	return t.target.Uuid, nil
}

func (t *Target) SetUUID(id string) (err error) {
	t.target.Uuid = id
	return t.Save()
}

func (t *Target) UI() (terminal.UI, error) {
	return t.ui, nil
}

func (t *Target) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Target{
		ResourceId: t.target.GetResourceId(),
		Project:    t.target.GetProject(),
		Name:       t.target.GetName(),
	}
}

// Name implements core.Target
func (t *Target) Name() (string, error) {
	return t.target.Name, nil
}

// SetName implements core.Target
func (t *Target) SetName(value string) (err error) {
	t.target.Name = value
	return t.Save()
}

// Provider implements core.Target
func (t *Target) Provider() (p core.Provider, err error) {
	i := t.cache.Get("provider")
	if i != nil {
		return i.(core.Provider), nil
	}

	providerName, err := t.ProviderName()
	if err != nil {
		return nil, err
	}
	if providerName == "" {
		return nil, errors.New("cannot fetch provider for target when provider name is blank")
	}
	provider, err := t.project.basis.component(
		t.ctx, component.ProviderType, providerName)

	if err != nil {
		return
	}
	p = provider.Value.(core.Provider)
	if err := seedPlugin(p, t); err != nil {
		return nil, err
	}

	t.cache.Register("provider", p)

	return
}

// ProviderName implements core.Target
func (t *Target) ProviderName() (string, error) {
	if t.target.Provider != "" {
		return t.target.Provider, nil
	}
	p, err := t.project.DefaultProvider(
		&core.DefaultProviderOptions{
			CheckUsable: true,
			MachineName: t.target.Name,
		},
	)
	if err != nil {
		return "", err
	}

	t.target.Provider = p

	return p, nil
}

// Communicate implements core.Target
func (t *Target) Communicate() (c core.Communicator, err error) {
	i := t.cache.Get("communicator")
	if i != nil {
		c = i.(core.Communicator)
		return
	}
	// TODO: get the communicator name from the Vagrantfile
	//       eg. t.target.Configuration.ConfigVm.Communicator
	communicatorName := "ssh"
	communicator, err := t.project.basis.component(
		t.ctx, component.CommunicatorType, communicatorName)

	if err != nil {
		return
	}
	c = communicator.Value.(core.Communicator)

	if err = seedPlugin(c, t); err != nil {
		t.logger.Error("failed to seed communicator plugin",
			"error", err,
		)

		return
	}
	t.cache.Register("communicator", c)

	return
}

// UpdatedAt implements core.Target
func (t *Target) UpdatedAt() (tm *time.Time, err error) {
	return
}

// Project implements core.Target
func (t *Target) Project() (core.Project, error) {
	return t.project, nil
}

// Metadata implements core.Target
func (t *Target) Metadata() (map[string]string, error) {
	return t.target.Metadata.Metadata, nil
}

// DataDir implements core.Target
func (t *Target) DataDir() (*datadir.Target, error) {
	return t.dir, nil
}

func (t *Target) State() (state core.State, err error) {
	switch t.target.State {
	case vagrant_server.Operation_UNKNOWN:
		state = core.UNKNOWN
	case vagrant_server.Operation_CREATED:
		state = core.CREATED
	case vagrant_server.Operation_DESTROYED:
		state = core.DESTROYED
	case vagrant_server.Operation_HALTED:
		state = core.HALTED
	case vagrant_server.Operation_NOT_CREATED:
		state = core.NOT_CREATED
	case vagrant_server.Operation_PENDING:
		state = core.PENDING
	default:
		state = core.UNKNOWN
	}
	return
}

// Record implements core.Target
func (t *Target) Record() (*anypb.Any, error) {
	return t.target.Record, nil
}

// Specialize implements core.Target
func (t *Target) Specialize(typ interface{}) (specialized interface{}, err error) {
	switch typ.(type) {
	case *core.Machine:
		specialized = t.Machine()
	}
	return
}

// Resource ID for this target
func (t *Target) ResourceId() (string, error) {
	return t.target.ResourceId, nil
}

// Returns the job info if currently set
func (t *Target) JobInfo() *component.JobInfo {
	return t.jobInfo
}

// Client returns the API client for the backend server.
func (t *Target) Client() *serverclient.VagrantClient {
	return t.project.basis.client
}

func (t *Target) Closer(c func() error) {
	t.closers = append(t.closers, c)
}

// Close is called to clean up resources allocated by the target.
// This should be called and blocked on to gracefully stop the target.
func (t *Target) Close() (err error) {
	t.logger.Debug("closing target",
		"target", t)

	for _, c := range t.closers {
		if cerr := c(); cerr != nil {
			t.logger.Warn("error executing closer",
				"error", cerr)

			err = multierror.Append(err, cerr)
		}
	}
	// Remove this target from built target list in project
	delete(t.project.targets, t.target.Name)
	return
}

// Saves the target to the db
func (t *Target) Save() (err error) {
	t.m.Lock()
	defer t.m.Unlock()

	t.logger.Debug("saving target to db",
		"target", t.target.ResourceId,
		"name", t.target.Name,
	)

	result, uerr := t.Client().UpsertTarget(t.ctx, &vagrant_server.UpsertTargetRequest{
		Target: t.target})
	if uerr != nil {
		t.logger.Trace("failed to save target",
			"target", t.target.ResourceId,
			"error", uerr)

		err = multierror.Append(err, uerr)

		return
	}
	t.target = result.Target
	return
}

func (t *Target) Destroy() (err error) {
	t.Close()
	t.m.Lock()
	defer t.m.Unlock()
	_, err = t.Client().DeleteTarget(t.ctx, &vagrant_server.DeleteTargetRequest{
		Target: t.Ref().(*vagrant_plugin_sdk.Ref_Target),
	})

	// Remove all the files inside the datadir without wiping the datadir itself
	files, err := filepath.Glob(filepath.Join(t.dir.DataDir().String(), "*"))
	if err != nil {
		return err
	}
	for _, file := range files {
		rerr := os.RemoveAll(file)
		if rerr != nil {
			err = multierror.Append(err, rerr)
		}
	}

	return
}

func (t *Target) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	t.logger.Debug("running new task",
		"target", t,
		"task", task)

	// Intialize targets
	if err = t.project.InitTargets(); err != nil {
		return err
	}

	cmd, err := t.project.basis.component(
		ctx, component.CommandType, task.Component.Name)

	if err != nil {
		t.logger.Error("failed to build requested component",
			"type", component.CommandType,
			"name", task.Component.Name,
			"error", err)
		return
	}

	fn := cmd.Value.(component.Command).ExecuteFunc(
		strings.Split(task.CommandName, " "))
	result, err := t.callDynamicFunc(ctx, t.logger, fn, (*int32)(nil),
		argmapper.Typed(task.CliArgs, t.jobInfo, t.dir, t.ctx, t.ui),
		argmapper.ConverterFunc(cmd.mappers...),
	)

	if err != nil || result == nil || result.(int32) != 0 {
		t.logger.Error("failed to execute command",
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

// LoadTarget implements originScope
func (t *Target) LoadTarget(topts ...TargetOption) (*Target, error) {
	return nil, fmt.Errorf("targets cannot be loaded from a target")
}

// Boxes implements originScope
func (t *Target) Boxes() (core.BoxCollection, error) {
	return nil, fmt.Errorf("boxes cannot be loaded from a target")
}

// Vagrantfile implements originScope / core.Target
func (t *Target) Vagrantfile() (core.Vagrantfile, error) {
	return t.vagrantfile, nil
}

// Cache implements originScope
func (t *Target) Cache() cacher.Cache {
	return t.project.basis.cache
}

// Broker implements originScope
func (t *Target) Broker() *goplugin.GRPCBroker {
	return t.project.basis.plugins.LegacyBroker()
}

func (t *Target) seed(fn func(*core.Seeds)) {
	t.project.seed(
		func(s *core.Seeds) {
			s.AddNamed("target", t)
			s.AddNamed("target_ui", t.ui)
			s.AddTyped(t)
			if fn != nil {
				fn(s)
			}
		},
	)
}

// Specializes target into a machine
func (t *Target) Machine() core.Machine {
	cm := t.cache.Get("machine")
	if cm != nil {
		return cm.(core.Machine)
	}

	targetMachine := &vagrant_server.Target_Machine{}
	t.target.Record.UnmarshalTo(targetMachine)
	m := &Machine{
		Target:      t,
		logger:      t.logger,
		machine:     targetMachine,
		cache:       cacher.New(),
		vagrantfile: t.vagrantfile,
	}

	t.Closer(func() error {
		return m.Save()
	})

	t.cache.Register("machine", m)

	return m
}

// Calls the function provided and converts the
// result to an expected type. If no type conversion
// is required, a `false` value for the expectedType
// will return the raw interface return value.
//
// By default, the target is added as a typed argument
// and the target and target UI are both added as a
// named arguments. Execution is passed up to the project
// level so it can set arguments as well.
func (t *Target) callDynamicFunc(
	ctx context.Context, // context for function execution
	log hclog.Logger, // logger to provide function execution
	f interface{}, // function to call
	expectedType interface{}, // nil pointer of expected return type
	args ...argmapper.Arg, // list of argmapper arguments
) (interface{}, error) {
	// ensure our UI status is closed after every call in case it is used
	defer t.ui.Status().Close()

	return t.project.callDynamicFunc(ctx, log, f, expectedType, args...)
}

func (t *Target) execHook(
	ctx context.Context,
	log hclog.Logger,
	h *config.Hook,
) error {
	return execHook(ctx, t, log, h)
}

func (t *Target) doOperation(
	ctx context.Context,
	log hclog.Logger,
	op operation,
) (interface{}, proto.Message, error) {
	return doOperation(ctx, log, t, op)
}

// Initialize the target instance
func (t *Target) init() (err error) {
	// As long as no error is encountered,
	// update the target configuration.
	defer func() {
		if err == nil {
			t.target.Configuration, err = t.vagrantfile.rootToStore()
		}
	}()
	t.logger.Info("running init on target", "target", t.target.Name)
	// Name or resource id is required for a target to be loaded
	if t.target.Name == "" && t.target.ResourceId == "" {
		return fmt.Errorf("cannot load a target without name or resource id")
	}

	// A parent project is also required
	if t.project == nil {
		return fmt.Errorf("cannot load a target without defined project")
	}

	// If the configuration was updated during load, save it so
	// we can re-apply after loading stored data
	var conf *vagrant_plugin_sdk.Args_ConfigData
	if t.target.Configuration != nil {
		conf = t.target.Configuration
	}

	// Pull target info
	resp, err := t.Client().FindTarget(t.ctx,
		&vagrant_server.FindTargetRequest{
			Target: t.target,
		},
	)
	if err != nil {
		return
	}
	t.target = resp.Target

	// If we have configuration data, re-apply it
	if conf != nil {
		t.target.Configuration = conf
	}

	// Set the project into the target
	t.target.Project = t.project.Ref().(*vagrant_plugin_sdk.Ref_Project)

	// If we have a vagrantfile attached, we're done
	if t.vagrantfile != nil {
		return
	}

	// If we don't have configuration data, just stub
	if t.target.Configuration == nil {
		t.target.Configuration = &vagrant_plugin_sdk.Args_ConfigData{}
		t.vagrantfile = t.project.vagrantfile.clone("target", t)
		t.vagrantfile.root = &component.ConfigData{
			Data: map[string]interface{}{},
		}
		return
	}

	t.logger.Info("vagrantfile has not been defined so generating from store config",
		"name", t.target.Name,
	)

	internal := plugin.NewInternal(
		t.project.basis.plugins.LegacyBroker(),
		t.project.basis.cache,
		t.project.basis.cleaner,
		t.logger,
		t.project.basis.mappers,
	)

	// Load the configuration data we have
	raw, err := dynamic.Map(
		t.target.Configuration,
		(**component.ConfigData)(nil),
		argmapper.ConverterFunc(t.project.basis.mappers...),
		argmapper.Typed(
			t.ctx,
			t.logger,
			internal,
		),
	)

	if err != nil {
		return
	}

	t.vagrantfile = t.project.vagrantfile.clone("target", t)
	t.vagrantfile.root = raw.(*component.ConfigData)

	return
}

// Options type for target loading
type TargetOption func(*Target) error

// Set a vagrantfile instance on target
func WithTargetVagrantfile(v *Vagrantfile) TargetOption {
	return func(t *Target) (err error) {
		t.vagrantfile = v
		return
	}
}

// Set name on target
func WithTargetName(name string) TargetOption {
	return func(t *Target) (err error) {
		t.target.Name = name
		return nil
	}
}

// Configure target with proto ref
func WithTargetRef(r *vagrant_plugin_sdk.Ref_Target) TargetOption {
	return func(t *Target) error {
		// Target ref must include a resource id or name
		if r.Name == "" && r.ResourceId == "" {
			return fmt.Errorf("target ref must include ResourceId and/or Name")
		}

		// Target ref must include project ref if resource id is empty
		if r.Name == "" && r.Project == nil {
			return fmt.Errorf("target ref must include Project for name lookup")
		}

		result, err := t.Client().FindTarget(t.ctx,
			&vagrant_server.FindTargetRequest{
				Target: &vagrant_server.Target{
					ResourceId: r.ResourceId,
					Name:       r.Name,
					Project:    r.Project,
				},
			},
		)

		if err != nil {
			return err
		}

		t.target = result.Target

		return nil
	}
}

func WithProvider(provider string) TargetOption {
	return func(t *Target) (err error) {
		if t != nil && t.target != nil && provider != "" {
			t.target.Provider = provider
		}
		return nil
	}
}

var _ core.Target = (*Target)(nil)
