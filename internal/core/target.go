package core

import (
	"context"
	"strings"

	"github.com/golang/protobuf/proto"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/serverclient"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type Machine struct {
	name       string
	resourceid string
	project    *Project
	logger     hclog.Logger
	config     *config.Machine
	dir        *datadir.Machine

	labels         map[string]string
	overrideLabels map[string]string

	jobInfo *component.JobInfo
	UI      terminal.UI
}

func (m *Machine) Ui() terminal.UI {
	return m.UI
}

func (m *Machine) Ref() interface{} {
	return &vagrant_server.Ref_Machine{
		ResourceId: m.resourceid,
		Name:       m.name,
		Project:    m.project.Ref().(*vagrant_server.Ref_Project),
	}
}

func (m *Machine) JobInfo() *component.JobInfo {
	return m.jobInfo
}

func (m *Machine) Client() *serverclient.VagrantClient {
	return m.project.basis.client
}

func (m *Machine) Close() (err error) {
	return
}

func (m *Machine) specializeComponent(c *Component) (cmp plugin.PluginMetadata, err error) {
	if cmp, err = m.project.specializeComponent(c); err != nil {
		return
	}
	cmp.SetRequestMetadata("machine_resource_id", m.resourceid)
	return
}

func (m *Machine) Run(ctx context.Context, task *vagrant_server.Task) (err error) {
	m.logger.Debug("running new task", "machine", m, "task", task)

	cmd, err := m.project.basis.component(
		ctx, component.CommandType, task.Component.Name)

	if err != nil {
		m.logger.Error("failed to build requested component", "type", component.CommandType,
			"name", task.Component.Name, "error", err)
		return err
	}

	if _, err = m.specializeComponent(cmd); err != nil {
		m.logger.Error("failed to specialize component", "type", component.CommandType,
			"name", task.Component.Name, "error", err)
		return err
	}

	result, err := m.callDynamicFunc(
		ctx,
		m.logger,
		(interface{})(nil),
		cmd,
		cmd.Value.(component.Command).ExecuteFunc(strings.Split(task.CommandName, " ")),
		argmapper.Typed(task.CliArgs),
	)

	if err != nil || result == nil || result.(int64) != 0 {
		m.logger.Error("failed to execute command", "type", component.CommandType,
			"name", task.Component.Name, "error", err)
		return err
	}

	return
}

func (m *Machine) callDynamicFunc(
	ctx context.Context,
	log hclog.Logger,
	result interface{}, // expected result type
	c *Component, // component
	f interface{}, // function
	args ...argmapper.Arg,
) (interface{}, error) {

	// Be sure that the status is closed after every operation so we don't leak
	// weird output outside the normal execution.
	defer m.UI.Status().Close()

	args = append(args,
		argmapper.Typed(
			m.jobInfo,
			m.dir,
			m.UI,
		),
	)

	return m.project.callDynamicFunc(ctx, log, result, c, f, args...)
}

func (m *Machine) mergeLabels(ls ...map[string]string) map[string]string {
	result := map[string]string{}

	// Merge order
	mergeOrder := []map[string]string{result, m.labels}
	mergeOrder = append(mergeOrder, ls...)
	mergeOrder = append(mergeOrder, m.overrideLabels)

	// Merge them
	return labelsMerge(mergeOrder...)
}

func (m *Machine) execHook(ctx context.Context, log hclog.Logger, h *config.Hook) error {
	return execHook(ctx, m, log, h)
}

func (m *Machine) doOperation(ctx context.Context, log hclog.Logger, op operation) (interface{}, proto.Message, error) {
	return doOperation(ctx, log, m, op)
}

var _ *Machine = (*Machine)(nil)
