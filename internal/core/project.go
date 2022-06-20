package core

import (
	"context"
	"errors"
	"fmt"
	"os"
	"sort"
	"strings"
	"sync"

	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"
	goplugin "github.com/hashicorp/go-plugin"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

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
	project     *vagrant_server.Project
	ctx         context.Context
	basis       *Basis
	logger      hclog.Logger
	targets     map[string]*Target
	dir         *datadir.Project
	mappers     []*argmapper.Func
	vagrantfile *Vagrantfile

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

func (p *Project) String() string {
	return fmt.Sprintf("core.Project:[basis: %s, name: %s, resource_id: %s, address: %p]",
		p.basis.Name(), p.project.Name, p.project.ResourceId, p)
}

// Cache implements originScope
func (p *Project) Cache() cacher.Cache {
	return p.basis.cache
}

// Broker implements originScope
func (p *Project) Broker() *goplugin.GRPCBroker {
	return p.basis.plugins.LegacyBroker()
}

// Vagrantfile implements originScope
func (p *Project) Vagrantfile() (core.Vagrantfile, error) {
	return p.vagrantfile, nil
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
		if st.IsActive() {
			activeTargets = append(activeTargets, t)
		}
	}
	return
}

// Config implements core.Project
func (p *Project) Config() (core.Vagrantfile, error) {
	return p.vagrantfile, nil
}

// Boxes implements core.Project
func (p *Project) Boxes() (bc core.BoxCollection, err error) {
	return p.basis.Boxes()
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

// VagrantfileName implements core.Project
func (p *Project) VagrantfileName() (name string, err error) {
	fullPath := path.NewPath(p.project.Configuration.Path.Path)
	return fullPath.Base().String(), nil
}

// DefaultProvider implements core.Project
func (p *Project) DefaultProvider(opts *core.DefaultProviderOptions) (string, error) {
	logger := p.logger.Named("default-provider")
	logger.Debug("Searching for default provider", "options", fmt.Sprintf("%#v", opts))
	// Algorithm ported from Vagrant::Environment#default_provider; structure
	// and comments mirrored from there.

	// Implement the algorithm from
	// https://www.vagrantup.com/docs/providers/basic_usage.html#default-provider
	// with additional steps 2.5 and 3.5 from
	// https://bugzilla.redhat.com/show_bug.cgi?id=1444492
	// to allow system-configured provider priorities.
	//
	// 1. The --provider flag on a vagrant up is chosen above all else, if it is
	//    present.
	//
	// (Step 1 is done by the caller; this method is only called if --provider
	// wasn't given.)
	//
	// 2. If the VAGRANT_DEFAULT_PROVIDER environmental variable is set, it
	//    takes next priority and will be the provider chosen.
	defaultProvider := os.Getenv("VAGRANT_DEFAULT_PROVIDER")
	if defaultProvider != "" && opts.ForceDefault {
		logger.Debug("Using forced default provider", "provider", defaultProvider)
		return defaultProvider, nil
	}

	// Get the list of providers in our configuration, in order
	configProviders := []string{}
	targets, err := p.vagrantfile.TargetNames()
	if err != nil {
		return "", err
	}

	for _, n := range targets {
		targetConfig, err := p.vagrantfile.TargetConfig(n, "", false)
		if err != nil {
			return "", err
		}
		tv := targetConfig.(*Vagrantfile)

		pRaw, err := tv.GetValue("vm", "__provider_order")
		providers, ok := pRaw.([]interface{})
		if !ok {
			return "", fmt.Errorf("unexpected type for target provider list (%T)", pRaw)
		}
		for _, pint := range providers {
			pstring, err := optionToString(pint)
			if err != nil {
				return "", fmt.Errorf("unexpected type for target provider (%T)", pint)
			}
			configProviders = append(configProviders, pstring)
		}
	}

	usableProviders := []*core.NamedPlugin{}
	pluginProviders, err := p.basis.plugins.ListPlugins("provider")
	if err != nil {
		return "", err
	}
	for _, pp := range pluginProviders {
		logger.Debug("considering plugin", "provider", pp.Name)

		// Skip excluded providers
		if opts.IsExcluded(pp.Name) {
			logger.Debug("skipping excluded provider", "provider", pp.Name)
			continue
		}

		plug, err := p.basis.plugins.GetPlugin(pp.Name, pp.Type)
		if err != nil {
			return "", err
		}

		plugOpts := plug.Options.(*component.ProviderOptions)
		logger.Debug("got provider options", "options", fmt.Sprintf("%#v", plugOpts))

		// Skip providers that can't be defaulted, unless they're in our
		// config, in which case someone made our decision for us.
		if !plugOpts.Defaultable {
			inConfig := false
			for _, cp := range configProviders {
				if cp == pp.Name {
					inConfig = true
				}
			}
			if !inConfig {
				logger.Debug("skipping non-defaultable provider", "provider", pp.Name)
				continue
			}
		}

		// Skip the providers that aren't usable.
		if opts.CheckUsable {
			logger.Debug("Checking usable on provider", "provider", pp.Name)
			pluginImpl := plug.Plugin.(core.Provider)
			usable, err := pluginImpl.Usable()
			if err != nil {
				return "", err
			}
			if !usable {
				logger.Debug("Skipping unusable provider", "provider", pp.Name)
				continue
			}
		}

		// If we made it here we have a candidate usable provider
		usableProviders = append(usableProviders, plug)
	}
	logger.Debug("Initial usable provider list", "usableProviders", usableProviders)

	// Sort by plugin priority, higher is first
	sort.SliceStable(usableProviders, func(i, j int) bool {
		iPriority := usableProviders[i].Options.(*component.ProviderOptions).Priority
		jPriority := usableProviders[j].Options.(*component.ProviderOptions).Priority
		return iPriority > jPriority
	})
	logger.Debug("Priority sorted usable provider list", "usableProviders", usableProviders)

	// If we're not forcing the default, but it's usable and hasn't been
	// otherwise excluded, return it now.
	for _, u := range usableProviders {
		if u.Name == defaultProvider {
			logger.Debug("Using default provider as it was found in usable list",
				"provider", u)
			return u.Name, nil
		}
	}

	// 2.5. Vagrant will go through all of the config.vm.provider calls in the
	//      Vagrantfile and try each in order. It will choose the first
	//      provider that is usable and listed in VAGRANT_PREFERRED_PROVIDERS.
	preferredProviders := strings.Split(os.Getenv("VAGRANT_PREFERRED_PROVIDERS"), ",")
	k := 0
	for _, pp := range preferredProviders {
		spp := strings.TrimSpace(pp) // .map { s.strip }
		if spp != "" {               // .select { !s.empty? }
			preferredProviders[k] = spp
			k++
		}
	}
	preferredProviders = preferredProviders[:k]

	for _, cp := range configProviders {
		for _, up := range usableProviders {
			if cp == up.Name {
				for _, pp := range preferredProviders {
					if cp == pp {
						logger.Debug("Using preferred provider detected in configuration and usable",
							"provider", pp)
						return pp, nil
					}
				}
			}
		}
	}

	// 3. Vagrant will go through all of the config.vm.provider calls in the
	//    Vagrantfile and try each in order. It will choose the first provider
	//    that is usable. For example, if you configure Hyper-V, it will never
	//    be chosen on Mac this way. It must be both configured and usable.
	for _, cp := range configProviders {
		for _, up := range usableProviders {
			if cp == up.Name {
				logger.Debug("Using provider detected in configuration and usable",
					"provider", cp)
				return cp, nil
			}
		}
	}

	// 3.5. Vagrant will go through VAGRANT_PREFERRED_PROVIDERS and find the
	//      first plugin that reports it is usable.
	for _, pp := range preferredProviders {
		for _, up := range usableProviders {
			if pp == up.Name {
				logger.Debug("Using preffered provider found in usable list",
					"provider", pp)
				return pp, nil
			}
		}
	}

	// 4. Vagrant will go through all installed provider plugins (including the
	//    ones that come with Vagrant), and find the first plugin that reports
	//    it is usable. There is a priority system here: systems that are known
	//    better have a higher priority than systems that are worse. For
	//    example, if you have the VMware provider installed, it will always
	//    take priority over VirtualBox.
	if len(usableProviders) > 0 {
		logger.Debug("Using the first provider from the usable list",
			"provider", usableProviders[0])
		return usableProviders[0].Name, nil
	}

	return "", errors.New("No default provider.")
}

// VagrantfilePath implements core.Project
func (p *Project) VagrantfilePath() (pp path.Path, err error) {
	pp = path.NewPath(p.project.Configuration.Path.Path).Parent()
	return
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

func (p *Project) Target(nameOrId string, provider string) (core.Target, error) {
	// TODO(spox): do we need to add a check here if the
	//             already loaded target doesn't match the
	//             provided provider name?
	if t, ok := p.targets[nameOrId]; ok {
		return t, nil
	}

	return p.vagrantfile.Target(nameOrId, provider)
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

// LoadTarget loads a target within the current project. If the target is not
// found, it will be created.
func (p *Project) LoadTarget(topts ...TargetOption) (t *Target, err error) {
	p.m.Lock()
	defer p.m.Unlock()

	// Create our target
	t = &Target{
		cache:   cacher.New(),
		ctx:     p.ctx,
		project: p,
		logger:  p.logger,
		target: &vagrant_server.Target{
			Project: p.Ref().(*vagrant_plugin_sdk.Ref_Project),
		},
		ui: p.ui,
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

	// Lookup target in cached list by name
	if c, ok := p.targets[t.target.Name]; ok {
		return c, nil
	}

	// Lookup target in cached list by resource id
	if c, ok := p.targets[t.target.ResourceId]; ok {
		return c, nil
	}

	// If we don't have a vagrantfile assigned to
	// this target, request it and set it
	if t.vagrantfile == nil {
		p.logger.Info("target does not have vagrantfile set, loading", "target", t.target.Name)
		tv, err := p.vagrantfile.TargetConfig(t.target.Name, "", false)
		if err != nil {
			return nil, err
		}
		t.vagrantfile = tv.(*Vagrantfile)
	}

	// If this is the first time through, re-init the target
	if err = t.init(); err != nil {
		return
	}

	// If the data directory is set, set it
	if t.dir == nil {
		if t.dir, err = p.dir.Target(t.target.Name); err != nil {
			return nil, err
		}
	}

	// Update the logger name based on the level
	if t.logger.IsTrace() {
		t.logger = t.logger.Named("target")
	} else {
		t.logger = t.logger.ResetNamed("vagrant.core.target")
	}

	// Ensure any modifications to the target are persisted
	t.Closer(func() error { return t.Save() })

	// Remove the target from the list when closed
	t.Closer(func() error {
		delete(p.targets, t.target.ResourceId)
		return nil
	})

	// Close the target when the project is closed
	p.Closer(func() error {
		return t.Close()
	})

	// Add the target to target list in project
	p.targets[t.target.ResourceId] = t
	p.targets[t.target.Name] = t

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
			s.AddTyped(p, p.vagrantfile)
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

	defer func() {
		if err != nil {
			p.logger.Error("failed to initialize targets",
				"error", err,
			)
		}
	}()

	p.logger.Trace("initializing targets defined within project",
		"project", p.Name())

	targets, err := p.vagrantfile.TargetNames()
	if err != nil {
		return
	}

	if len(targets) == 0 {
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
	for _, t := range targets {
		_, err = p.Client().UpsertTarget(p.ctx,
			&vagrant_server.UpsertTargetRequest{
				Target: &vagrant_server.Target{
					Name:    t,
					Project: p.Ref().(*vagrant_plugin_sdk.Ref_Project),
				},
			},
		)
		if err != nil {
			p.logger.Error("failed to initialize target with project",
				"project", p.Name(),
				"target", t,
				"error", err,
			)

			return
		}
		updated = true
	}

	if updated {
		// If targets have been updated then refresh the project. This is required
		// since upserting targets will also update the project to have a reference
		// to the new targets.
		err = p.refreshProject()
	}
	return
}

// Get's the latest project from the DB
func (p *Project) refreshProject() (err error) {
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
