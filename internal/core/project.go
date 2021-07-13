package core

import (
	"context"
	"errors"
	"strings"
	"sync"

	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/factory"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// Project represents a project with one or more applications.
//
// The Close function should be called when finished with the project
// to properly clean up any open resources.
type Project struct {
	project   *vagrant_server.Project
	ctx       context.Context
	basis     *Basis
	config    *config.Project
	logger    hclog.Logger
	targets   map[string]*Target
	factories map[component.Type]*factory.Factory
	dir       *datadir.Project
	mappers   []*argmapper.Func

	// jobInfo is the base job info for executed functions.
	jobInfo *component.JobInfo

	// This lock only needs to be held currently to protect closers.
	lock sync.Mutex

	// The below are resources we need to close when Close is called, if non-nil
	closers []func() error

	// UI is the terminal UI to use for messages related to the project
	// as a whole. These messages will show up unprefixed for example compared
	// to the app-specific UI.
	ui terminal.UI
}

// UI implements core.Project
func (p *Project) UI() (terminal.UI, error) {
	return p.ui, nil
}

// CWD implements core.Project
func (p *Project) CWD() (path string, err error) {
	// TODO: implement
	return
}

// DataDir implements core.Project
func (p *Project) DataDir() (*datadir.Project, error) {
	return p.dir, nil
}

// VagrantfileName implements core.Project
func (p *Project) VagrantfileName() (name string, err error) {
	// TODO: implement
	return "VagrantFile", nil
}

// Home implements core.Project
func (p *Project) Home() (path string, err error) {
	// TODO: implement
	return "/home", nil
}

// LocalData implements core.Project
func (p *Project) LocalData() (path string, err error) {
	// TODO: implement
	return "/local/data", nil
}

// Tmp implements core.Project
func (p *Project) Tmp() (path string, err error) {
	// TODO: implement
	return
}

// DefaultPrivateKey implements core.Project
func (p *Project) DefaultPrivateKey() (path string, err error) {
	// TODO: implement
	return "/key/path", nil
}

// Host implements core.Project
func (p *Project) Host() (host core.Host, err error) {
	return p.basis.Host()
}

// MachineNames implements core.Project
func (p *Project) MachineNames() (names []string, err error) {
	// TODO: implement
	return []string{"test"}, nil
}

// Target implements core.Project
func (p *Project) Target(nameOrId string) (core.Target, error) {
	if t, ok := p.targets[nameOrId]; ok {
		return t, nil
	}
	for _, t := range p.targets {
		if t.target.ResourceId == nameOrId {
			return t, nil
		}
	}
	return nil, errors.New("requested target does not exist")
}

// TargetNames implements core.Project
func (p *Project) TargetNames() ([]string, error) {
	var names []string
	for _, t := range p.project.Targets {
		names = append(names, t.Name)
	}
	return names, nil
}

// TargetIds implements core.Project
func (p *Project) TargetIds() ([]string, error) {
	var ids []string
	for _, t := range p.project.Targets {
		ids = append(ids, t.ResourceId)
	}
	return ids, nil
}

// Custom name defined for this project
func (p *Project) Name() string {
	return p.project.Name
}

// Resource ID for this project
func (p *Project) ResourceId() string {
	return p.project.ResourceId
}

// Returns the job info if currently set
func (p *Project) JobInfo() *component.JobInfo {
	return p.jobInfo
}

// Load a project within the current basis. If the project is not found, it
// will be created.
func (p *Project) LoadTarget(topts ...TargetOption) (t *Target, err error) {
	// Create our target
	t = &Target{
		ctx:     p.ctx,
		project: p,
		logger:  p.logger,
		ui:      p.ui,
	}

	// Apply any options provided
	for _, opt := range topts {
		if oerr := opt(t); oerr != nil {
			err = multierror.Append(err, oerr)
		}
	}

	if err != nil {
		return
	}

	// If the machine is already loaded, return that
	if target, ok := p.targets[t.target.ResourceId]; ok {
		return target, nil
	}

	p.targets[t.target.ResourceId] = t

	if t.logger.IsTrace() {
		t.logger = t.logger.Named("target")
	} else {
		t.logger = t.logger.ResetNamed("vagrant.core.target")
	}

	if t.dir == nil {
		if t.dir, err = p.dir.Target(t.target.Name); err != nil {
			return
		}
	}

	// Ensure any modifications to the target are persisted
	t.Closer(func() error { return t.Save() })

	return
}

// Client returns the API client for the backend server.
func (p *Project) Client() *serverclient.VagrantClient {
	return p.basis.client
}

// Ref returns the project ref for API calls.
func (p *Project) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Project{
		ResourceId: p.project.ResourceId,
		Name:       p.project.Name,
		Basis:      p.project.Basis,
	}
}

func (p *Project) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	p.logger.Debug("running new task",
		"project", p,
		"task", task)

	cmd, err := p.basis.component(
		ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	if _, err = p.specializeComponent(cmd); err != nil {
		return
	}

	fn := cmd.Value.(component.Command).ExecuteFunc(
		strings.Split(task.CommandName, " "))
	result, err := p.callDynamicFunc(ctx, p.logger, fn, (*int32)(nil),
		argmapper.Typed(task.CliArgs, p.jobInfo, p.dir),
	)

	p.logger.Warn("completed running command from project", "result", result)

	if err != nil || result == nil || result.(int32) != 0 {
		p.logger.Error("failed to execute command",
			"type", component.CommandType,
			"name", task.Component.Name,
			"result", result,
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

// Register functions to be called when closing this project
func (p *Project) Closer(c func() error) {
	p.closers = append(p.closers, c)
}

// Close is called to clean up resources allocated by the project.
// This should be called and blocked on to gracefully stop the project.
func (p *Project) Close() (err error) {
	defer p.lock.Unlock()
	p.lock.Lock()

	p.logger.Debug("closing project",
		"project", p)

	// close all the loaded targets
	for name, m := range p.targets {
		p.logger.Trace("closing target",
			"target", name)

		if cerr := m.Close(); cerr != nil {
			p.logger.Warn("error closing target",
				"target", name,
				"err", cerr)

			err = multierror.Append(err, cerr)
		}
	}

	for _, f := range p.closers {
		if cerr := f(); cerr != nil {
			p.logger.Warn("error executing closer",
				"error", cerr)

			err = multierror.Append(err, cerr)
		}
	}
	// Remove this project from built project list in basis
	delete(p.basis.projects, p.Name())
	return
}

// Saves the project to the db
func (p *Project) Save() (err error) {
	p.logger.Trace("saving project to db",
		"project", p.ResourceId())

	_, err = p.Client().UpsertProject(p.ctx,
		&vagrant_server.UpsertProjectRequest{
			Project: p.project,
		},
	)
	if err != nil {
		p.logger.Trace("failed to save project",
			"project", p.ResourceId())
	}
	return
}

// Saves the project to the db as well as any targets that have been loaded
func (p *Project) SaveFull() (err error) {
	p.logger.Debug("performing full save",
		"project", p.project.ResourceId)

	for _, t := range p.targets {
		p.logger.Trace("saving target",
			"project", p.project.ResourceId,
			"target", t.target.ResourceId)

		if terr := t.Save(); terr != nil {
			p.logger.Trace("error while saving target",
				"target", t.target.ResourceId,
				"error", err)

			err = multierror.Append(err, terr)
		}
	}
	if perr := p.Save(); perr != nil {
		err = multierror.Append(err, perr)
	}
	return
}

func (p *Project) Components(ctx context.Context) ([]*Component, error) {
	return p.basis.components(ctx)
}

// Calls the function provided and converts the
// result to an expected type. If no type conversion
// is required, a `false` value for the expectedType
// will return the raw interface return value.
//
// By default, the project is added as a typed argument
// and the project and project UI are both added as a
// named arguments. Execution is passed up to the basis
// level so it can set arguments as well and actually
// execute the function.
func (p *Project) callDynamicFunc(
	ctx context.Context, // context for function execution
	log hclog.Logger, // logger to provide function execution
	f interface{}, // function to call
	expectedType interface{}, // nil pointer of expected return type
	args ...argmapper.Arg, // list of argmapper arguments
) (interface{}, error) {
	// ensure our UI status is closed after every call in case it is used
	defer p.ui.Status().Close()

	// add project related arguments
	args = append(args,
		argmapper.Typed(p),
		argmapper.Named("project", p),
		argmapper.Named("project_ui", p.UI),
	)

	return p.basis.callDynamicFunc(ctx, log, f, expectedType, args...)
}

// Specialize a given component. This is specifically used for
// Ruby based legacy Vagrant components.
//
// TODO: Since legacy Vagrant is no longer directly connecting
// to the Vagrant server, this should probably be removed.
func (p *Project) specializeComponent(
	c *Component, // component to specialize
) (cmp plugin.PluginMetadata, err error) {
	if cmp, err = p.basis.specializeComponent(c); err != nil {
		return
	}
	cmp.SetRequestMetadata("project_resource_id", p.ResourceId())
	return
}

func (p *Project) execHook(
	ctx context.Context,
	log hclog.Logger,
	h *config.Hook,
) error {
	return execHook(ctx, p, log, h)
}

func (p *Project) doOperation(
	ctx context.Context,
	log hclog.Logger,
	op operation,
) (interface{}, proto.Message, error) {
	return doOperation(ctx, log, p, op)
}

// options is the configuration to construct a new Project. Some
// configuration is set directly on the Project. This is only used for
// intermediate values that need to be processed further before initializing
// the project.
type options struct {
	Config *config.Project
}

// ProjectOption is used to set options for LoadProject
type ProjectOption func(*Project) error

func WithBasis(b *Basis) ProjectOption {
	return func(p *Project) (err error) {
		p.basis = b
		return
	}
}

func WithProjectDataDir(dir *datadir.Project) ProjectOption {
	return func(p *Project) (err error) {
		p.dir = dir
		return
	}
}

func WithProjectName(name string) ProjectOption {
	return func(p *Project) (err error) {
		if p.basis == nil {
			return errors.New("basis must be set before loading project")
		}
		if ex := p.basis.Project(name); ex != nil {
			p.project = ex.project
			return
		}

		var match *vagrant_plugin_sdk.Ref_Project
		for _, m := range p.basis.basis.Projects {
			if m.Name == name {
				match = m
				break
			}
		}
		if match == nil {
			return errors.New("project is not registered in basis")
		}
		result, err := p.Client().FindProject(p.ctx, &vagrant_server.FindProjectRequest{
			Project: &vagrant_server.Project{Name: name},
		})
		if err != nil {
			return
		}
		if !result.Found {
			p.logger.Error("failed to locate project during setup", "project", name,
				"basis", p.basis.Ref())
			return errors.New("failed to load project")
		}
		p.project = result.Project

		return
	}
}

// WithBasisRef is used to load or initialize the basis
func WithProjectRef(r *vagrant_plugin_sdk.Ref_Project) ProjectOption {
	return func(p *Project) (err error) {
		// Basis must be set before we continue
		if p.basis == nil {
			return errors.New("basis must be set before loading project")
		}

		var project *vagrant_server.Project
		// Check if the basis has already loaded the project. If so,
		// then initialize on that project
		if ex := p.basis.projects[r.Name]; ex != nil {
			project = ex.project
			return
		}
		result, err := p.Client().FindProject(p.ctx,
			&vagrant_server.FindProjectRequest{
				Project: &vagrant_server.Project{
					Name: r.Name,
					Path: r.Path,
				},
			},
		)
		if err != nil {
			return err
		}
		if result.Found {
			project = result.Project
		} else {
			var result *vagrant_server.UpsertProjectResponse
			result, err = p.Client().UpsertProject(p.ctx,
				&vagrant_server.UpsertProjectRequest{
					Project: &vagrant_server.Project{
						Name:  r.Name,
						Path:  r.Name,
						Basis: r.Basis,
					},
				},
			)
			if err != nil {
				return
			}
			project = result.Project
		}
		// Before we init, validate basis is consistent
		if project.Basis.ResourceId != r.Basis.ResourceId {
			p.logger.Error("invalid basis for project", "request-basis", r.Basis,
				"project-basis", project.Basis)
			return errors.New("project basis configuration is invalid")
		}
		p.project = project

		return
	}
}

var _ core.Project = (*Project)(nil)
