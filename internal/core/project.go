package core

import (
	"context"
	"io"
	"strings"
	"sync"

	"github.com/golang/protobuf/proto"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
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
	basis     *Basis
	config    *config.Project
	logger    hclog.Logger
	machines  map[string]*Machine
	factories map[component.Type]*factory.Factory
	dir       *datadir.Project
	mappers   []*argmapper.Func
	env       *Environment

	// name is the name of the project
	name string

	// path is the location of the project
	path string

	// resourceid is the unique identifier of the project
	resourceid string

	// labels is the list of labels that are assigned to this project.
	labels map[string]string

	// jobInfo is the base job info for executed functions.
	jobInfo *component.JobInfo

	// This lock only needs to be held currently to protect localClosers.
	lock sync.Mutex

	// The below are resources we need to close when Close is called, if non-nil
	localClosers []io.Closer

	// UI is the terminal UI to use for messages related to the project
	// as a whole. These messages will show up unprefixed for example compared
	// to the app-specific UI.
	UI terminal.UI

	// overrideLabels are the labels specified via the CLI to override
	// all other conflicting keys.
	overrideLabels map[string]string
}

func (p *Project) Ui() terminal.UI {
	return p.UI
}

func (p *Project) JobInfo() *component.JobInfo {
	return p.jobInfo
}

func (p *Project) Environment() *Environment {
	return p.env
}

func (p *Project) MachineFromRef(r *vagrant_server.Ref_Machine) (*Machine, error) {
	var machine *vagrant_server.Machine
	if r.ResourceId != "" {
		result, err := p.Client().GetMachine(
			context.Background(),
			&vagrant_server.GetMachineRequest{
				Project: p.Ref().(*vagrant_server.Ref_Project),
				Machine: r,
			},
		)
		if err != nil {
			return nil, err
		}
		machine = result.Machine
	} else {
		result, err := p.Client().UpsertMachine(
			context.Background(),
			&vagrant_server.UpsertMachineRequest{
				Project: p.Ref().(*vagrant_server.Ref_Project),
				Machine: &vagrant_server.Machine{
					Name:    r.Name,
					Project: p.Ref().(*vagrant_server.Ref_Project),
				},
			},
		)
		if err != nil {
			return nil, err
		}
		machine = result.Machine
	}
	mdir, err := p.dir.Machine(machine.Name)
	if err != nil {
		return nil, err
	}
	m := &Machine{
		name:       machine.Name,
		resourceid: machine.ResourceId,
		project:    p,
		logger:     p.logger.Named(machine.Name),
		dir:        mdir,
		UI:         p.UI,
	}

	return m, nil
}

// App initializes and returns the machine with the given name.
func (p *Project) Machine(name string) (*Machine, error) {
	m, ok := p.machines[name]
	if !ok {
		d, err := p.dir.Machine(name)
		if err != nil {
			return nil, err
		}
		m = &Machine{
			name:    name,
			project: p,
			logger:  p.logger.Named(name),
			dir:     d,
			UI:      p.UI,
		}
		p.machines[name] = m
	}
	return p.machines[name], nil
}

// Client returns the API client for the backend server.
func (p *Project) Client() *serverclient.VagrantClient {
	return p.basis.client
}

// Ref returns the project ref for API calls.
func (p *Project) Ref() interface{} {
	return &vagrant_server.Ref_Project{
		ResourceId: p.resourceid,
		Name:       p.name,
		Basis:      p.basis.Ref().(*vagrant_server.Ref_Basis),
	}
}

func (p *Project) Components(ctx context.Context) (results []*Component, err error) {
	if results, err = p.basis.Components(ctx); err != nil {
		return
	}

	for _, cc := range componentCreatorMap {
		c, err := cc.Create(ctx, p, "")
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

func (p *Project) specializeComponent(c *Component) (cmp plugin.PluginMetadata, err error) {
	if cmp, err = p.basis.specializeComponent(c); err != nil {
		return
	}
	cmp.SetRequestMetadata("project_resource_id", p.resourceid)
	return
}

func (p *Project) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	p.logger.Debug("running new task", "project", p, "task", task)

	cmd, err := p.basis.component(ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}
	defer cmd.Close()

	if _, err = p.specializeComponent(cmd); err != nil {
		return
	}

	result, err := p.callDynamicFunc(
		ctx,
		p.logger,
		(interface{})(nil),
		cmd,
		cmd.Value.(component.Command).ExecuteFunc(strings.Split(task.CommandName, " ")),
		argmapper.Typed(task.CliArgs),
		// TODO: add extra args here
		argmapper.Typed(p.env),
	)
	if err != nil || result == nil || result.(int64) != 0 {
		p.logger.Error("failed to execute command", "type", component.CommandType, "name", task.Component.Name, "result", result, "error", err)
		return err
	}

	return
}

// Close is called to clean up resources allocated by the project.
// This should be called and blocked on to gracefully stop the project.
func (p *Project) Close() error {
	p.lock.Lock()
	defer p.lock.Unlock()

	p.logger.Debug("closing project", "project", p)

	// Stop all our machines (not sure what this actually affects)
	for name, m := range p.machines {
		p.logger.Trace("closing machine", "machine", name)
		if err := m.Close(); err != nil {
			p.logger.Warn("error closing machine", "err", err)
		}
	}

	// If we're running in local mode, close our local resources we started
	for _, c := range p.localClosers {
		if err := c.Close(); err != nil {
			return err
		}
	}
	p.localClosers = nil

	return nil
}

func (p *Project) callDynamicFunc(
	ctx context.Context,
	log hclog.Logger,
	result interface{}, // expected result type
	c *Component, // component
	f interface{}, // function
	args ...argmapper.Arg,
) (interface{}, error) {

	// Be sure that the status is closed after every operation so we don't leak
	// weird output outside the normal execution.
	defer p.UI.Status().Close()

	args = append(args,
		argmapper.ConverterFunc(p.mappers...),
		argmapper.Typed(
			p.jobInfo,
			p.dir,
			p.UI,
		),
	)

	return p.basis.callDynamicFunc(ctx, log, result, c, f, args...)
}

// mergeLabels merges the set of labels given. This will set the project
// labels as a base automatically and then merge ls in order.
func (p *Project) mergeLabels(ls ...map[string]string) map[string]string {
	result := map[string]string{}

	// Set our builtin labels
	// result["vagrant/workspace"] = p.workspace

	// Merge order
	mergeOrder := []map[string]string{result, p.labels}
	mergeOrder = append(mergeOrder, ls...)
	mergeOrder = append(mergeOrder, p.overrideLabels)

	// Merge them
	return labelsMerge(mergeOrder...)
}

func (p *Project) execHook(ctx context.Context, log hclog.Logger, h *config.Hook) error {
	return execHook(ctx, p, log, h)
}

func (p *Project) doOperation(ctx context.Context, log hclog.Logger, op operation) (interface{}, proto.Message, error) {
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
type ProjectOption func(*Project, *options)

// WithConfig uses the given project configuration for initializing the
// Project. This configuration must be validated already prior to using this
// option.
func WithConfig(c *config.Project) ProjectOption {
	return func(p *Project, opts *options) {
		opts.Config = c
	}
}

func WithBasis(b *Basis) ProjectOption {
	return func(p *Project, opts *options) {
		p.basis = b
	}
}

func WithProjectDataDir(dir *datadir.Project) ProjectOption {
	return func(p *Project, opts *options) {
		p.dir = dir
	}
}

func WithProjectRef(r *vagrant_server.Ref_Project) ProjectOption {
	return func(p *Project, opts *options) {
		var project *vagrant_server.Project
		// if we don't have a resource ID we need to upsert
		if r.ResourceId == "" {
			result, err := p.Client().UpsertProject(
				context.Background(),
				&vagrant_server.UpsertProjectRequest{
					Project: &vagrant_server.Project{
						Name:  r.Name,
						Path:  r.Name,
						Basis: r.Basis,
					},
				},
			)
			if err != nil {
				panic("failed to upsert project") // TODO(spox): don't panic
			}
			project = result.Project
		} else {
			result, err := p.Client().GetProject(
				context.Background(),
				&vagrant_server.GetProjectRequest{
					Project: r,
				},
			)
			if err != nil {
				panic("failed to retrieve project") // TODO(spox): don't panic
			}
			project = result.Project
		}
		p.name = project.Name
		p.resourceid = project.ResourceId
		p.path = project.Path
		if p.dir == nil {
			var err error
			p.dir, err = datadir.NewProject(p.path + "/.vagrant")
			if err != nil {
				panic("failed to create project data dir") // TODO(spox): don't panic
			}
		}
	}
}

var _ *Project = (*Project)(nil)
