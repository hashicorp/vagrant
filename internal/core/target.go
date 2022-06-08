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
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/serverclient"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Target struct {
	ctx     context.Context
	target  *vagrant_server.Target
	project *Project
	logger  hclog.Logger
	dir     *datadir.Target

	m       sync.Mutex
	jobInfo *component.JobInfo
	closers []func() error
	ui      terminal.UI
	cache   cacher.Cache
}

func (b *Target) Config() *vagrant_plugin_sdk.Vagrantfile_MachineConfig {
	return b.target.Configuration
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
		ResourceId: t.target.ResourceId,
		Project:    t.target.Project,
		Name:       t.target.Name,
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
	defer func() {
		if p != nil {
			err = seedPlugin(p, t)
			if err == nil {
				t.cache.Register("provider", p)
			}
		}
	}()
	i := t.cache.Get("provider")
	if i != nil {
		p = i.(core.Provider)
		return
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

	return
}

// ProviderName implements core.Target
func (t *Target) ProviderName() (string, error) {
	return t.target.Provider, nil
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

	result, err := t.Client().UpsertTarget(t.ctx, &vagrant_server.UpsertTargetRequest{
		Target: t.target})
	if err != nil {
		t.logger.Trace("failed to save target",
			"target", t.target.ResourceId,
			"error", err)
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
		Target:  t,
		logger:  t.logger,
		machine: targetMachine,
		cache:   cacher.New(),
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

type TargetOption func(*Target) error

func WithTargetName(name string) TargetOption {
	return func(t *Target) (err error) {
		if ex, _ := t.project.Target(name, ""); ex != nil {
			if et, ok := ex.(*Target); ok {
				t.target = et.target
			}
			return
		}
		for _, target := range t.project.targets {
			if target.target.Name != name {
				continue
			}
			var result *vagrant_server.GetTargetResponse
			result, err = t.Client().GetTarget(t.ctx,
				&vagrant_server.GetTargetRequest{
					Target: target.Ref().(*vagrant_plugin_sdk.Ref_Target)})
			if err != nil {
				return
			}
			t.target = result.Target
			return
		}
		return fmt.Errorf("target `%s' is not registered in project", name)
	}
}

func WithTargetRef(r *vagrant_plugin_sdk.Ref_Target) TargetOption {
	return func(t *Target) (err error) {
		// Project must be set before we continue
		if t.project == nil {
			return fmt.Errorf("project must be set before loading target")
		}

		var target *vagrant_server.Target
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
		if result != nil {
			target = result.Target
		} else {
			var result *vagrant_server.UpsertTargetResponse
			result, err = t.Client().UpsertTarget(t.ctx,
				&vagrant_server.UpsertTargetRequest{
					Target: &vagrant_server.Target{
						ResourceId: r.ResourceId,
						Name:       r.Name,
						Project:    r.Project,
					},
				},
			)
			if err != nil {
				return
			}
			target = result.Target
		}
		if r.Project != nil && target.Project.ResourceId != r.Project.ResourceId {
			t.logger.Error("invalid project for target",
				"request-project", r.Project,
				"target-project", target.Project)

			return fmt.Errorf("target project configuration is invalid")
		}
		t.target = target
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
