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
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/serverclient"
	"google.golang.org/grpc"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Target struct {
	ctx     context.Context
	target  *vagrant_server.Target
	project *Project
	logger  hclog.Logger
	config  *config.Target
	dir     *datadir.Target

	grpcServer *grpc.Server
	lock       sync.Mutex
	jobInfo    *component.JobInfo
	closers    []func() error
	UI         terminal.UI
}

func (t *Target) Ui() terminal.UI {
	return t.UI
}

func (t *Target) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Target{
		ResourceId: t.target.ResourceId,
		Project:    t.target.Project,
	}
}

func (t *Target) Name() string {
	return t.target.Name
}

func (t *Target) ResourceId() string {
	return t.target.ResourceId
}

func (t *Target) JobInfo() *component.JobInfo {
	return t.jobInfo
}

func (t *Target) Client() *serverclient.VagrantClient {
	return t.project.basis.client
}

func (t *Target) Closer(c func() error) {
	t.closers = append(t.closers, c)
}

func (t *Target) Close() (err error) {
	defer t.lock.Unlock()
	t.lock.Lock()

	t.logger.Debug("closing target", "target", t)

	for _, c := range t.closers {
		if cerr := c(); cerr != nil {
			t.logger.Warn("error executing closer", "error", cerr)
			err = multierror.Append(err, cerr)
		}
	}
	// Remove this target from built target list in project
	delete(t.project.targets, t.target.Name)
	return
}

func (t *Target) Save() (err error) {
	t.logger.Debug("saving target to db", "target", t.ResourceId())
	_, err := t.Client().UpsertTarget(t.ctx, &vagrant_server.UpsertTargetRequest{
		Target: t.target})
	if err != nil {
		t.logger.Trace("failed to save target", "target", t.ResourceId(), "error", err)
	}
	return
}

func (t *Target) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	t.logger.Debug("running new task", "target", t, "task", task)

	cmd, err := t.project.basis.component(
		ctx, component.CommandType, task.Component.Name)

	if err != nil {
		t.logger.Error("failed to build requested component", "type", component.CommandType,
			"name", task.Component.Name, "error", err)
		return
	}

	if _, err = t.specializeComponent(cmd); err != nil {
		t.logger.Error("failed to specialize component", "type", component.CommandType,
			"name", task.Component.Name, "error", err)
		return
	}

	result, err := t.callDynamicFunc(
		ctx,
		t.logger,
		(interface{})(nil),
		cmd,
		cmd.Value.(component.Command).ExecuteFunc(strings.Split(task.CommandName, " ")),
		argmapper.Typed(task.CliArgs),
	)

	if err != nil || result == nil || result.(int64) != 0 {
		t.logger.Error("failed to execute command", "type", component.CommandType,
			"name", task.Component.Name, "error", err)
	}

	return
}

func (t *Target) callDynamicFunc(
	ctx context.Context,
	log hclog.Logger,
	result interface{}, // expected result type
	c *Component, // component
	f interface{}, // function
	args ...argmapper.Arg,
) (interface{}, error) {

	// Be sure that the status is closed after every operation so we don't leak
	// weird output outside the normal execution.
	defer t.UI.Status().Close()

	args = append(args,
		argmapper.Typed(
			t.jobInfo,
			t.dir,
			t.UI,
		),
	)

	return t.project.callDynamicFunc(ctx, log, result, c, f, args...)
}

func (t *Target) specializeComponent(c *Component) (cmp plugin.PluginMetadata, err error) {
	if cmp, err = t.project.specializeComponent(c); err != nil {
		return
	}
	cmp.SetRequestMetadata("target_resource_id", t.target.ResourceId)
	return
}

func (t *Target) execHook(ctx context.Context, log hclog.Logger, h *config.Hook) error {
	return execHook(ctx, t, log, h)
}

func (t *Target) doOperation(ctx context.Context, log hclog.Logger, op operation) (interface{}, proto.Message, error) {
	return doOperation(ctx, log, t, op)
}

type TargetOption func(*Target) error

func WithTargetName(name string) TargetOption {
	return func(t *Target) (err error) {
		if ex := t.project.Target(name); ex != nil {
			t.target = ex.target
			return
		}
		for _, target := range t.project.targets {
			if target.Name() != name {
				continue
			}
			var result *vagrant_server.GetTargetResponse
			result, err = t.Client().GetTarget(t.ctx,
				&vagrant_server.GetTargetRequest{Target: target.Ref().(*vagrant_plugin_sdk.Ref_Target)})
			if err != nil {
				return
			}
			t.target = result.Target
			t.project.targets[t.target.Name] = t
			return
		}
		return errors.New("target is not registered in project")
	}
}

func WithTargetRef(r *vagrant_plugin_sdk.Ref_Target) TargetOption {
	return func(t *Target) (err error) {
		// Project must be set before we continue
		if t.project == nil {
			return errors.New("project must be set before loading target")
		}

		var target *vagrant_server.Target
		if ex := t.project.Target(r.Name); ex != nil {
			t.target = ex.target
			return
		}
		result, err := t.Client().FindTarget(t.ctx,
			&vagrant_server.FindTargetRequest{
				Target: &vagrant_server.Target{
					Name: r.Name,
				},
			},
		)
		if err != nil {
			return err
		}
		if result.Found {
			target = result.Target
		} else {
			var result *vagrant_server.UpsertTargetResponse
			result, err = t.Client().UpsertTarget(t.ctx,
				&vagrant_server.UpsertTargetRequest{
					Target: &vagrant_server.Target{
						Name:    r.Name,
						Project: r.Project,
					},
				},
			)
			if err != nil {
				return
			}
			target = result.Target
		}
		if target.Project.ResourceId != r.Project.ResourceId {
			t.logger.Error("invalid project for target", "request-project", r.Project,
				"target-project", target.Project)
			return errors.New("target project configuration is invalid")
		}
		t.target = target
		t.project.targets[t.Name()] = t
		return
	}
}

var _ *Target = (*Target)(nil)
