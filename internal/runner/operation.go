package runner

import (
	"context"
	"fmt"
	"path/filepath"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	configpkg "github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/factory"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (r *Runner) LoadPlugins(cfg *configpkg.Config) error {
	// Start with loading plugins from the Ruby runtime
	plugins, err := r.vagrantRubyRuntime.GetPlugins()
	if err != nil {
		return err
	}

	for _, p := range plugins {
		r.logger.Info("loading ruby plugin", "name", p.Name, "type", p.Type)
		cfg.TrackRubyPlugin(p.Name, []interface{}{p.Type})
	}

	// Now lets load builtin plugins
	for name, options := range plugin.Builtins {
		if plugin.IN_PROCESS_PLUGINS {
			if err := r.builtinPlugins.Add(name, options...); err != nil {
				return err
			}
		}

		cfg.TrackBuiltinPlugin(name, []interface{}{component.CommandType})
	}

	return nil
}

// executeJob executes an assigned job. This will source the data (if necessary),
// setup the project, execute the job, and return the outcome.
func (r *Runner) executeJob(
	ctx context.Context,
	log hclog.Logger,
	ui terminal.UI,
	job *vagrant_server.Job,
	wd string,
) (result *vagrant_server.Job_Result, err error) {
	// Eventually we'll need to extract the data source. For now we're
	// just building for local exec so it is the working directory.
	path := configpkg.Filename
	if wd != "" {
		path = filepath.Join(wd, path)
	}

	// Setup our basis configuration
	cfg, err := configpkg.Load("", "")
	if err != nil {
		log.Warn("failed here for basis trying to read configuration", "path", path)
		// return
		cfg = &configpkg.Config{}
	}

	// Determine the evaluation context we'll be using
	log.Trace("reading configuration", "path", path)
	cfg, err = configpkg.Load(path, filepath.Dir(path))
	if err != nil {
		log.Warn("failed here trying to read configuration", "path", path)
		cfg = &configpkg.Config{}
		// return nil, err
	}

	// Build our job info
	jobInfo := &component.JobInfo{
		Id:    job.Id,
		Local: r.local,
	}

	log.Debug("job we are processing", "job", job, "basis", job.Basis, "project", job.Project, "machine", job.Machine)

	// Load our basis
	b, err := core.NewBasis(ctx,
		core.WithBasisConfig(cfg),
		core.WithLogger(log),
		core.WithUI(ui),
		core.WithComponents(r.factories),
		core.WithClient(r.client),
		core.WithJobInfo(jobInfo),
		core.WithBasisRef(job.Basis),
	)
	if err != nil {
		return
	}

	defer b.Close()

	// Lets check for a project, and if we have one,
	// load it up now
	var p *core.Project

	if job.Project != nil {
		p, err = b.LoadProject(ctx,
			core.WithConfig(&configpkg.Project{}),
			core.WithProjectRef(job.Project),
		)
		if err != nil {
			return
		}
		defer p.Close()
	}

	// Finally, if we have a machine defined, load it up
	var m *core.Machine

	if job.Machine != nil && p != nil && job.Machine.Name != "" {
		m, err = p.MachineFromRef(job.Machine)
		if err != nil {
			return
		}
		defer m.Close()
	}

	// Execute the operation
	log.Info("executing operation", "type", fmt.Sprintf("%T", job.Operation))
	switch job.Operation.(type) {
	case *vagrant_server.Job_Noop_:
		if r.noopCh != nil {
			select {
			case <-r.noopCh:
			case <-ctx.Done():
				return nil, ctx.Err()
			}
		}

		log.Debug("noop job success")
		return nil, nil

	case *vagrant_server.Job_Init:
		return r.executeInitOp(ctx, job, b)

	case *vagrant_server.Job_Run:
		log.Warn("running a run operation against project", "project", p, "job", job)
		return r.executeRunOp(ctx, job, p)

	case *vagrant_server.Job_Auth:
		return r.executeAuthOp(ctx, log, job, p)

	case *vagrant_server.Job_Docs:
		return r.executeDocsOp(ctx, log, job, p)

	default:
		return nil, status.Errorf(codes.Aborted, "unknown operation %T", job.Operation)
	}
}

func (r *Runner) pluginFactories(
	log hclog.Logger,
	plugins []*configpkg.Plugin,
	wd string,
) (map[component.Type]*factory.Factory, error) {
	// Copy all our base factories first
	result := map[component.Type]*factory.Factory{}
	for k, f := range r.factories {
		result[k] = f.Copy()
	}

	// Get our plugin search paths
	pluginPaths, err := plugin.DefaultPaths(wd)
	if err != nil {
		return nil, err
	}
	log.Debug("plugin search path", "path", pluginPaths)

	// Search for all of our plugins
	var perr error
	for _, pluginCfg := range plugins {
		plog := log.With("plugin_name", pluginCfg.Name)

		// If this is a ruby plugin, register it using the ruby factory
		if pluginCfg.Type.Ruby {
			for _, t := range pluginCfg.Types() {
				plog.Debug("registering ruby plugin", "name", pluginCfg.Name, "type", t)
				result[t].Register(
					pluginCfg.Name,
					plugin.BuiltinRubyFactory(
						r.vagrantRubyRuntime,
						pluginCfg.Name,
						t,
					),
				)
			}
			continue
		}

		// If this a builtin plugin, register it using the builtin factory
		if pluginCfg.Type.Builtin {
			for _, t := range pluginCfg.Types() {
				plog.Debug("registering builtin plugin", "name", pluginCfg.Name, "type", t)
				if plugin.IN_PROCESS_PLUGINS {
					result[t].Register(
						pluginCfg.Name,
						r.builtinPlugins.Factory(
							pluginCfg.Name,
							t,
						),
					)
				} else {
					result[t].Register(
						pluginCfg.Name,
						plugin.BuiltinFactory(
							pluginCfg.Name,
							t,
						),
					)
				}
			}
			continue
		}

		// Now we can search for the plugin outside of vagrant
		plog.Debug("searching for plugin")

		// Find our plugin.
		cmd, err := plugin.Discover(pluginCfg, pluginPaths)
		if err != nil {
			plog.Warn("error searching for plugin", "err", err)
			perr = multierror.Append(perr, err)
			continue
		}

		// If the plugin was not found, it is only an error if
		// we don't have it already registered.
		if cmd == nil {
			if _, ok := plugin.Builtins[pluginCfg.Name]; !ok {
				perr = multierror.Append(perr, fmt.Errorf(
					"plugin %q not found",
					pluginCfg.Name))
				plog.Warn("plugin not found")
			} else {
				plog.Debug("plugin found as builtin")
				for _, t := range pluginCfg.Types() {
					result[t].Register(
						pluginCfg.Name,
						plugin.BuiltinFactory(
							pluginCfg.Name,
							t,
						),
					)
				}
			}

			continue
		}

		// Register the command
		plog.Debug("plugin found as external binary", "path", cmd.Path)
		for _, t := range pluginCfg.Types() {
			result[t].Register(pluginCfg.Name, plugin.Factory(cmd, t))
		}
	}

	return result, perr
}
