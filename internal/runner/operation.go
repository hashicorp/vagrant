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
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	configpkg "github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/factory"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func (r *Runner) LoadPlugins(cfg *configpkg.Config) error {
	// Start with loading plugins from the Ruby runtime
	plugins, err := r.vagrantRubyClient.GetPlugins()
	if err != nil {
		return err
	}

	for _, p := range plugins {
		r.logger.Info("loading ruby plugin", "name", p.Name, "type", p.Type)
		cfg.TrackRubyPlugin(p.Name, []interface{}{p.Type})
	}

	components := []interface{}{}
	for typ, _ := range plugin.BaseFactories {
		components = append(components, typ)
	}
	// Now lets load builtin plugins
	for name, options := range plugin.Builtins {
		r.logger.Info("loading builtin plugin " + name)

		if plugin.IN_PROCESS_PLUGINS {
			if err := r.builtinPlugins.Add(name, options...); err != nil {
				return err
			}
		}

		cfg.TrackBuiltinPlugin(name, components)
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
	// TODO(spox): config loading needs to be moved to core within basis and project
	path := configpkg.Filename
	if wd != "" {
		path = filepath.Join(wd, path)
	}

	// Setup our basis configuration
	// cfg, err := configpkg.Load("", "")
	// if err != nil {
	// 	log.Warn("failed here for basis trying to read configuration", "path", path)
	// 	// return
	// 	cfg = &configpkg.Config{}
	// }

	// Determine the evaluation context we'll be using
	log.Trace("reading configuration", "path", path)
	cfg, err := configpkg.Load(path, filepath.Dir(path))
	if err != nil {
		log.Warn("failed here trying to read configuration", "path", path)
		cfg = &configpkg.Config{}
		// return nil, err
	}
	log.Trace("configuration loaded", "cfg", cfg)

	// Build our job info
	jobInfo := &component.JobInfo{
		Id:    job.Id,
		Local: r.local,
	}

	log.Debug("processing operation ", "job", job, "basis", job.Basis,
		"project", job.Project, "target", job.Target)

	// Initial options for setting up the basis
	opts := []core.BasisOption{
		core.WithLogger(log),
		core.WithUI(ui),
		core.WithComponents(r.factories),
		core.WithClient(r.client),
		core.WithJobInfo(jobInfo),
	}

	var scope Runs

	// Work backwards to setup the basis
	var ref *vagrant_plugin_sdk.Ref_Basis
	if job.Target != nil {
		ref = job.Target.Project.Basis
	} else if job.Project != nil {
		ref = job.Project.Basis
	} else {
		ref = job.Basis
	}
	opts = append(opts, core.WithBasisRef(ref))

	// Load our basis
	b, err := core.NewBasis(ctx, opts...)
	if err != nil {
		return
	}

	defer b.Close()
	scope = b

	// Lets check for a project, and if we have one,
	// load it up now
	var p *core.Project

	if job.Project != nil {
		p, err = b.LoadProject(
			core.WithProjectRef(job.Project),
		)
		if err != nil {
			return
		}
		defer p.Close()
		scope = p
	}

	// Finally, if we have a target defined, load it up
	var m *core.Target

	if job.Target != nil && p != nil && job.Target.Name != "" {
		m, err = p.LoadTarget(core.WithTargetRef(job.Target))
		if err != nil {
			return
		}
		defer m.Close()
		scope = m
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
		log.Warn("running a run operation", "scope", scope, "job", job)
		return r.executeRunOp(ctx, job, scope)

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
