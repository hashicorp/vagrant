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
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

const DEFAULT_COMMUNICATOR_NAME = "ssh"

type Target struct {
	cache       cacher.Cache                // local target cache
	cleanup     cleanup.Cleanup             // cleanup tasks to be run on close
	client      *serverclient.VagrantClient // client to vagrant server
	ctx         context.Context             // local target context
	dir         *datadir.Target             // data directory for target
	factory     *Factory                    // scope factory
	jobInfo     *component.JobInfo          // jobInfo is the base job info for executed functions
	logger      hclog.Logger                // target specific logger
	project     *Project                    // project which owns this target
	ready       bool                        // flag that instance is ready
	target      *vagrant_server.Target      // stored target data
	ui          terminal.UI                 // target UI
	vagrantfile *Vagrantfile                // vagrantfile instance for target

	m sync.Mutex
}

func NewTarget(opts ...TargetOption) (*Target, error) {
	var t *Target
	var err error
	t = &Target{
		cache:   cacher.New(),
		cleanup: cleanup.New(),
		ctx:     context.Background(),
		logger:  hclog.L(),
		target:  &vagrant_server.Target{},
	}

	for _, fn := range opts {
		if optErr := fn(t); optErr != nil {
			err = multierror.Append(err, optErr)
		}
	}

	if err != nil {
		return nil, err
	}

	return t, err
}

func (t *Target) Init() error {
	var err error

	// If ready then Init was already run
	if t.ready {
		return nil
	}

	// Configure our logger
	t.logger = t.logger.ResetNamed("vagrant.core.target")

	// If no client is set, grab it from the project
	if t.client == nil && t.project != nil {
		t.client = t.project.client
	}

	// Attempt to reload the target to populate our
	// data. If the target is not found, create it.
	err = t.Reload()
	if err != nil {
		stat, ok := status.FromError(err)
		if !ok || stat.Code() != codes.NotFound {
			return err
		}
		// Target doesn't exist so save it to persist
		if err = t.Save(); err != nil {
			return err
		}
	}

	// If we don't have a project set, load it
	if t.project == nil {
		t.project, err = t.factory.NewProject(WithProjectRef(t.target.Project))
		if err != nil {
			return fmt.Errorf("failed to load target project: %w", err)
		}
	}

	// Always ensure the project reference is set
	t.target.Project = t.project.Ref().(*vagrant_plugin_sdk.Ref_Project)

	// If the target directory is unset, set it
	if t.dir == nil {
		if t.dir, err = t.project.dir.Target(t.target.Name); err != nil {
			return err
		}
	}

	// If the ui is unset, use the project ui
	if t.ui == nil {
		t.ui = t.project.ui
	}

	// Save ourself when closed
	t.Closer(func() error {
		return t.Save()
	})

	// If we have a vagrantfile set, we are done
	if t.vagrantfile != nil {
		t.vagrantfile.logger = t.logger.Named("vagrantfile")

		return nil
	}

	// We don't have a vagrantfile set so we need to restore
	// our stored configuration. First, make sure we have some
	// store configuration!
	if t.target.Configuration == nil {
		t.target.Configuration = &vagrant_plugin_sdk.Args_ConfigData{}

		// Since we don't have any data to load, just stub and return
		t.vagrantfile = t.project.vagrantfile.clone("target")
		t.vagrantfile.root = &component.ConfigData{
			Data: map[string]interface{}{},
		}

		return nil
	}

	v := t.project.vagrantfile.clone("target")
	v.logger = t.logger.Named("vagrantfile")

	if err = v.loadToRoot(t.target.Configuration); err != nil {
		return err
	}
	t.vagrantfile = v

	// Set flag that this instance is setup
	t.ready = true

	// Include this target information in log lines
	t.logger = t.logger.With("target", t)
	t.logger.Info("target initialized")

	return nil
}

func (t *Target) String() string {
	return fmt.Sprintf("core.Target[basis: %s, project: %s, resource_id: %s, name: %s, address: %p]",
		t.project.basis.Name(), t.project.Name(), t.target.ResourceId, t.target.Name, t,
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
	communicatorName := ""
	rawCommunicatorName, err := t.vagrantfile.GetValue("vm", "communicator")
	// If there is an error getting the communicator, default to using the ssh communicator
	if err != nil {
		communicatorName = DEFAULT_COMMUNICATOR_NAME
	}
	if rawCommunicatorName == nil {
		communicatorName = DEFAULT_COMMUNICATOR_NAME
	} else {
		communicatorName, err = optionToString(rawCommunicatorName)
		if err != nil {
			return nil, err
		}
	}
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

// Returns if the target exists based on state
func (t *Target) Exists() bool {
	s, _ := t.State()
	if s == core.NOT_CREATED || s == core.UNKNOWN {
		return false
	}
	return true
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
	return t.client
}

func (t *Target) Closer(c func() error) {
	t.cleanup.Do(c)
}

// Close is called to clean up resources allocated by the target.
// This should be called and blocked on to gracefully stop the target.
func (t *Target) Close() (err error) {
	t.logger.Debug("closing target")

	return t.cleanup.Close()
}

// Reload the target data
func (t *Target) Reload() (err error) {
	t.m.Lock()
	defer t.m.Unlock()

	result, err := t.Client().FindTarget(t.ctx,
		&vagrant_server.FindTargetRequest{
			Target: t.target,
		},
	)

	if err != nil {
		return
	}

	t.target = result.Target
	return
}

// Saves the target to the db
func (t *Target) Save() (err error) {
	t.m.Lock()
	defer t.m.Unlock()

	t.logger.Debug("saving target to db")

	// If there were any modification to the configuration
	// after init, be sure we capture them
	if t.vagrantfile != nil {
		t.target.Configuration, err = t.vagrantfile.rootToStore()
		if err != nil {
			t.logger.Warn("failed to serialize configuration prior to save",
				"error", err,
			)
			// Only warn since we want to save whatever information we can
			err = nil
		}
	}

	result, err := t.Client().UpsertTarget(t.ctx, &vagrant_server.UpsertTargetRequest{
		Target: t.target})
	if err != nil {
		t.logger.Trace("failed to save target",
			"error", err)

		return
	}
	t.target = result.Target
	return
}

func (t *Target) Destroy() (err error) {
	// Run all the cleanup tasks on the target
	t.m.Lock()
	defer t.m.Unlock()

	t.logger.Trace("destroying target")

	// Delete the target from the database
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

func (t *Target) Run(ctx context.Context, task *vagrant_server.Job_CommandOp) (err error) {
	t.logger.Debug("running new command",
		"command", task)

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
		strings.Split(task.Command, " "))
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

// Vagrantfile implements core.Target
func (t *Target) Vagrantfile() (core.Vagrantfile, error) {
	return t.vagrantfile, nil
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
		logger:      t.logger.Named("machine"),
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

// Options type for target loading
type TargetOption func(*Target) error

func WithProject(p *Project) TargetOption {
	return func(t *Target) (err error) {
		t.project = p
		t.target.Project = p.Ref().(*vagrant_plugin_sdk.Ref_Project)
		return
	}
}

func WithTargetProjectRef(p *vagrant_plugin_sdk.Ref_Project) TargetOption {
	return func(t *Target) (err error) {
		t.target.Project = p
		return
	}
}

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
	return func(t *Target) (err error) {
		if r.Name != "" {
			t.target.Name = r.Name
		}
		if r.ResourceId != "" {
			t.target.ResourceId = r.ResourceId
		}
		if r.Project != nil {
			t.target.Project = r.Project
		}

		return
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
var _ Scope = (*Target)(nil)
