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
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// Project represents a project with one or more applications.
//
// The Close function should be called when finished with the project
// to properly clean up any open resources.
type Project struct {
	project *vagrant_server.Project
	ctx     context.Context
	basis   *Basis
	logger  hclog.Logger
	targets map[string]*Target
	dir     *datadir.Project
	mappers []*argmapper.Func

	// jobInfo is the base job info for executed functions.
	jobInfo *component.JobInfo

	// This lock only needs to be held currently to protect closers.
	m sync.Mutex

	// The below are resources we need to close when Close is called, if non-nil
	closers []func() error

	// UI is the terminal UI to use for messages related to the project
	// as a whole. These messages will show up unprefixed for example compared
	// to the app-specific UI.
	ui terminal.UI
}

// ActiveTargets implements core.Project
func (p *Project) ActiveTargets() (activeTargets []core.Target, err error) {
	targets, err := p.Targets()
	if err != nil {
		return nil, err
	}
	activeTargets = []core.Target{}
	for _, t := range targets {
		st, err := t.State()
		if err != nil {
			return nil, err
		}
		if st == core.CREATED {
			activeTargets = append(activeTargets, t)
		}
	}
	return
}

// Boxes implements core.Project
func (p *Project) Boxes() (bc core.BoxCollection, err error) {
	return p.basis.Boxes()
}

// Config implements core.Project
func (b *Project) Config() (*vagrant_plugin_sdk.Vagrantfile_Vagrantfile, error) {
	return b.project.Configuration, nil
}

// CWD implements core.Project
func (p *Project) CWD() (path path.Path, err error) {
	return paths.VagrantCwd()
}

// DataDir implements core.Project
func (p *Project) DataDir() (*datadir.Project, error) {
	return p.dir, nil
}

// DefaultPrivateKey implements core.Project
func (p *Project) DefaultPrivateKey() (path path.Path, err error) {
	return p.basis.DefaultPrivateKey()
}

// DefaultProvider implements core.Project
func (p *Project) DefaultProvider() (name string, err error) {
	// TODO: This needs to implement the default provider algorithm
	// from https://www.vagrantup.com/docs/providers/basic_usage.html#default-provider
	return "virtualbox", nil
}

// Home implements core.Project
func (p *Project) Home() (dir path.Path, err error) {
	return path.NewPath(p.project.Path), nil
}

// Host implements core.Project
func (p *Project) Host() (host core.Host, err error) {
	return p.basis.Host()
}

// LocalData implements core.Project
func (p *Project) LocalData() (d path.Path, err error) {
	return p.dir.DataDir(), nil
}

// PrimaryTargetName implements core.Project
func (p *Project) PrimaryTargetName() (name string, err error) {
	// TODO: This needs the Vagrantfile service to be implemented
	return
}

// Resource implements core.Project
func (p *Project) ResourceId() (string, error) {
	return p.project.ResourceId, nil
}

// RootPath implements core.Project
func (p *Project) RootPath() (path path.Path, err error) {
	// TODO: need vagrantfile loading to be completed in order to implement
	return
}

// Target implements core.Project
func (p *Project) Target(nameOrId string) (core.Target, error) {
	if t, ok := p.targets[nameOrId]; ok {
		return t, nil
	}
	// Check for name or id
	for _, t := range p.targets {
		if t.target.Name == nameOrId {
			return t, nil
		}
		if t.target.ResourceId == nameOrId {
			return t, nil
		}
	}
	// Finally try loading it
	return p.LoadTarget(
		WithTargetRef(
			&vagrant_plugin_sdk.Ref_Target{
				Project:    p.Ref().(*vagrant_plugin_sdk.Ref_Project),
				Name:       nameOrId,
				ResourceId: nameOrId,
			},
		),
	)
}

// TargetIds implements core.Project
func (p *Project) TargetIds() ([]string, error) {
	var ids []string
	for _, t := range p.project.Targets {
		ids = append(ids, t.ResourceId)
	}
	return ids, nil
}

// TargetIndex implements core.Project
func (p *Project) TargetIndex() (index core.TargetIndex, err error) {
	return p.basis.TargetIndex()
}

// TargetNames implements core.Project
func (p *Project) TargetNames() ([]string, error) {
	var names []string
	for _, t := range p.project.Targets {
		names = append(names, t.Name)
	}
	return names, nil
}

// Tmp implements core.Project
func (p *Project) Tmp() (path path.Path, err error) {
	return p.dir.TempDir(), nil
}

// UI implements core.Project
func (p *Project) UI() (terminal.UI, error) {
	return p.ui, nil
}

// VagrantfileName implements core.Project
func (p *Project) VagrantfileName() (name string, err error) {
	fullPath := path.NewPath(p.project.Configuration.Path)
	return fullPath.Base().String(), nil
}

// VagrantfilePath implements core.Project
func (p *Project) VagrantfilePath() (pp path.Path, err error) {
	pp = path.NewPath(p.project.Configuration.Path).Parent()
	return
}

// Targets
func (p *Project) Targets() ([]core.Target, error) {
	var targets []core.Target
	for _, ref := range p.project.Targets {
		t, err := p.LoadTarget(WithTargetRef(ref))
		if err != nil {
			return nil, err
		}
		targets = append(targets, t)
	}
	return targets, nil
}

// Custom name defined for this project
func (p *Project) Name() string {
	return p.project.Name
}

// Returns the job info if currently set
func (p *Project) JobInfo() *component.JobInfo {
	return p.jobInfo
}

// Load a project within the current basis. If the project is not found, it
// will be created.
func (p *Project) LoadTarget(topts ...TargetOption) (t *Target, err error) {
	p.m.Lock()
	defer p.m.Unlock()

	// Create our target
	t = &Target{
		cache:   cacher.New(),
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
		return nil, err
	}

	if t.dir == nil {
		if t.dir, err = p.dir.Target(t.target.Name); err != nil {
			return nil, err
		}
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

	// Intialize targets
	if err = p.InitTargets(); err != nil {
		return err
	}

	cmd, err := p.basis.component(
		ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	fn := cmd.Value.(component.Command).ExecuteFunc(
		strings.Split(task.CommandName, " "))
	result, err := p.callDynamicFunc(ctx, p.logger, fn, (*int32)(nil),
		argmapper.Typed(ctx, task.CliArgs, p.jobInfo),
		argmapper.ConverterFunc(cmd.mappers...),
	)

	p.logger.Warn("completed running command from project", "result", result)

	if err != nil || result == nil || result.(int32) != 0 {
		p.logger.Error("failed to execute command",
			"type", component.CommandType,
			"name", task.Component.Name,
			"result", result,
			"error", err,
		)

		cmdErr := &runError{}
		if err != nil {
			cmdErr.err = err
			if st, ok := status.FromError(err); ok {
				cmdErr.status = st.Proto()
			}
		}
		if result != nil {
			cmdErr.exitCode = result.(int32)
		}

		return cmdErr
	}

	return
}

func (p *Project) seed(fn func(*core.Seeds)) {
	p.basis.seed(
		func(s *core.Seeds) {
			s.AddNamed("project", p)
			s.AddNamed("project_ui", p.ui)
			s.AddTyped(p)
			if fn != nil {
				fn(s)
			}
		},
	)
}

// Register functions to be called when closing this project
func (p *Project) Closer(c func() error) {
	p.closers = append(p.closers, c)
}

// Close is called to clean up resources allocated by the project.
// This should be called and blocked on to gracefully stop the project.
func (p *Project) Close() (err error) {
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
	p.m.Lock()
	defer p.m.Unlock()

	p.logger.Trace("saving project to db",
		"project", p.project.ResourceId)

	result, err := p.Client().UpsertProject(p.ctx,
		&vagrant_server.UpsertProjectRequest{
			Project: p.project,
		},
	)
	if err != nil {
		p.logger.Trace("failed to save project",
			"project", p.project.ResourceId)
	}

	p.project = result.Project

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

func (p *Project) InitTargets() (err error) {
	p.m.Lock()
	defer p.m.Unlock()

	p.logger.Trace("initializing targets defined within project",
		"project", p.Name())

	if p.project.Configuration == nil || p.project.Configuration.MachineConfigs == nil {
		p.logger.Trace("no targets defined within current project",
			"project", p.Name())

		return
	}

	// Get list of all currently known targets for project
	var existingTargets []string
	for _, t := range p.project.Targets {
		existingTargets = append(existingTargets, t.Name)
	}
	p.logger.Trace("known targets within project",
		"project", p.Name(),
		"targets", existingTargets,
	)

	updated := false
	for _, t := range p.project.Configuration.MachineConfigs {
		if t == nil {
			continue
		}
		_, err = p.Client().UpsertTarget(p.ctx,
			&vagrant_server.UpsertTargetRequest{
				Target: &vagrant_server.Target{
					Name:          t.Name,
					Project:       p.Ref().(*vagrant_plugin_sdk.Ref_Project),
					Configuration: t,
				},
			},
		)
		if err != nil {
			p.logger.Error("failed to initialize target with project",
				"project", p.Name(),
				"target", t.Name,
				"error", err,
			)

			return
		}
		updated = true
	}

	if !updated {
		return
	}

	result, err := p.Client().FindProject(p.ctx,
		&vagrant_server.FindProjectRequest{
			Project: &vagrant_server.Project{
				ResourceId: p.project.ResourceId,
			},
		},
	)
	if err != nil {
		p.logger.Error("failed to refresh project data",
			"project", p.Name(),
			"error", err,
		)

		return
	}

	p.project = result.Project

	return
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

	return p.basis.callDynamicFunc(ctx, log, f, expectedType, args...)
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
		if result == nil {
			p.logger.Error("failed to locate project during setup", "project", name,
				"basis", p.basis.Ref())
			return errors.New("failed to load project")
		}
		p.project = result.Project

		return
	}
}

// WithBasisRef is used to load or initialize the project
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
					Basis: r.Basis,
					Name:  r.Name,
					Path:  r.Path,
				},
			},
		)
		if err != nil {
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
		} else {
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
