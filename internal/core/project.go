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
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"google.golang.org/protobuf/proto"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"

	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// Project represents a project with one or more applications.
//
// The Close function should be called when finished with the project
// to properly clean up any open resources.
type Project struct {
	basis       *Basis                      // basis which owns this project
	cache       cacher.Cache                // local project cache
	cleanup     cleanup.Cleanup             // cleanup tasks to be run on close
	client      *serverclient.VagrantClient // client to vagrant server
	ctx         context.Context             // local context
	dir         *datadir.Project            // data directory for project
	factory     *Factory                    // scope factory
	jobInfo     *component.JobInfo          // jobInfo is the base job info for executed functions
	logger      hclog.Logger                // project specific logger
	mappers     []*argmapper.Func           // mappers for project
	plugins     *plugin.Manager             // project scoped plugin manager
	project     *vagrant_server.Project     // stored project data
	ready       bool                        // flag that instance is ready
	targets     map[string]*Target
	ui          terminal.UI  // project UI (non-prefixed)
	vagrantfile *Vagrantfile // vagrantfile instance for project

	m sync.Mutex
}

// Create a new blank project instance
func NewProject(opts ...ProjectOption) (*Project, error) {
	var p *Project
	var err error
	p = &Project{
		cache:   cacher.New(),
		cleanup: cleanup.New(),
		ctx:     context.Background(),
		logger:  hclog.L(),
		project: &vagrant_server.Project{
			Configuration: &vagrant_server.Vagrantfile{
				Unfinalized: &vagrant_plugin_sdk.Args_Hash{},
				Format:      vagrant_server.Vagrantfile_RUBY,
			},
		},
	}

	for _, fn := range opts {
		if optErr := fn(p); optErr != nil {
			err = multierror.Append(err, optErr)
		}
	}

	if err != nil {
		return nil, err
	}

	return p, nil
}

func (p *Project) Init() error {
	var err error

	// If ready then Init was already run
	if p.ready {
		return nil
	}

	// Configure our logger
	p.logger = p.logger.ResetNamed("vagrant.core.project")

	// If the client isn't set, grab it from the basis
	if p.client == nil && p.basis != nil {
		p.client = p.basis.client
	}

	// Attempt to reload the project to populate our
	// data. If the project is not found, create it.
	err = p.Reload()
	if err != nil {
		stat, ok := status.FromError(err)
		if !ok || stat.Code() != codes.NotFound {
			return err
		}
		// Project doesn't exist so save it to persist
		if err = p.Save(); err != nil {
			return err
		}
	}

	// If our reloaded data does not include any configuration
	// stub in a default value
	if p.project.Configuration == nil {
		p.project.Configuration = &vagrant_server.Vagrantfile{
			Unfinalized: &vagrant_plugin_sdk.Args_Hash{},
			Format:      vagrant_server.Vagrantfile_RUBY,
		}
	}

	// If we don't have a basis set, load it
	if p.basis == nil {
		p.basis, err = p.factory.NewBasis(p.project.Basis.ResourceId, WithBasisRef(p.project.Basis))
		if err != nil {
			return fmt.Errorf("failed to load project basis: %w", err)
		}
	}

	// Set our plugin manager as a sub manager of the basis
	p.plugins = p.basis.plugins.Sub("project")

	// If our project closes early, close the plugin sub manager
	// so it isn't just hanging around
	p.Closer(func() error {
		return p.plugins.Close()
	})

	// Always ensure the basis reference is set
	p.project.Basis = p.basis.Ref().(*vagrant_plugin_sdk.Ref_Basis)

	// If the project directory is unset, set it
	if p.dir == nil {
		if p.dir, err = p.basis.dir.Project(p.project.Name); err != nil {
			return err
		}
	}

	// If the ui is unset, use basis ui
	if p.ui == nil {
		p.ui = p.basis.ui
	}

	// Load any plugins that may be installed locally to the project
	if err = p.plugins.Discover(path.NewPath(p.project.Path).Join(".vagrant").Join("plugins")); err != nil {
		p.logger.Error("project setup failed during plugin discovery",
			"directory", path.NewPath(p.project.Path).Join(".vagrant").Join("plugins"),
			"error", err,
		)
		return err
	}

	// Clone our vagrantfile to use in the new project
	v := p.basis.vagrantfile.clone("project")
	v.logger = p.logger.Named("vagrantfile")

	// Add the project vagrantfile
	err = v.Source(p.project.Configuration, VAGRANTFILE_PROJECT)
	if err != nil {
		return err
	}
	// Init the vagrantfile so the config is available
	if err = v.Init(); err != nil {
		return err
	}
	p.vagrantfile = v

	// Store our configuration
	sv, err := v.GetSource(VAGRANTFILE_PROJECT)
	if err != nil {
		return err
	}
	p.project.Configuration = sv

	// Set our ref into vagrantfile
	p.vagrantfile.targetSource = p.Ref().(*vagrant_plugin_sdk.Ref_Project)

	// Set project seeds
	p.seed(nil)

	// Initialize any targets which are known to the project
	if err = p.InitTargets(); err != nil {
		return err
	}

	// Scrub any targets that no longer exist
	// NOTE: We access the cleanup directly here instead of using the
	//       generic Closer() so we can use Append(). This adds the
	//       target scrubbing task to a collection of cleanup tasks
	//       that are performed after the general collection has been
	//       run. This ensures that any target created by the factory
	//       will have been shut down and saved before this scrubbing
	//       task is executed.
	p.cleanup.Append(func() error {
		return p.scrubTargets()
	})

	// Save ourself when closed
	p.Closer(func() error {
		return p.Save()
	})

	// Set flag that this instance is setup
	p.ready = true

	// Include this project information in log lines
	p.logger = p.logger.With("project", p)
	p.logger.Info("project initialized")

	return nil
}

// Provide nice output in logger
func (p *Project) String() string {
	return fmt.Sprintf("core.Project:[basis: %v, name: %s, resource_id: %s, address: %p]",
		p.basis, p.project.Name, p.project.ResourceId, p)
}

// Vagrantfile implements core.Project
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
		target, err := p.Target(n, "")
		if err != nil {
			return "", nil
		}
		if target.(*Target).target.Provider != "" {
			configProviders = append(configProviders, target.(*Target).target.Provider)
		} else {
			tv := target.(*Target).vagrantfile

			pRaw, err := tv.GetValue("vm", "__provider_order")
			if err != nil {
				continue
			}
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
			if !usable {
				logger.Debug("Skipping unusable provider", "provider", pp.Name)
				continue
			}
			if err != nil {
				return "", err
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
	return p.vagrantfile.PrimaryTargetName()
}

// Resource implements core.Project
func (p *Project) ResourceId() (string, error) {
	return p.project.ResourceId, nil
}

// RootPath implements core.Project
func (p *Project) RootPath() (path.Path, error) {
	return path.NewPath(p.project.Configuration.Path.Path), nil
}

func (p *Project) Factory() *Factory {
	return p.basis.factory
}

// Target implements core.Project
func (p *Project) Target(nameOrId string, provider string) (core.Target, error) {
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
	names, err := p.TargetNames()
	if err != nil {
		return nil, err
	}
	targets := make([]core.Target, len(names))
	for i, n := range names {
		t, err := p.Target(n, "")
		if err != nil {
			return nil, err
		}
		targets[i] = t
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

// Client returns the API client for the backend server.
func (p *Project) Client() *serverclient.VagrantClient {
	return p.client
}

// Ref returns the project ref for API calls.
func (p *Project) Ref() interface{} {
	return &vagrant_plugin_sdk.Ref_Project{
		ResourceId: p.project.ResourceId,
		Name:       p.project.Name,
		Basis:      p.project.Basis,
	}
}

func (p *Project) Run(ctx context.Context, task *vagrant_server.Job_CommandOp) (err error) {
	p.logger.Debug("running new command",
		"command", task)

	cmd, err := p.basis.component(
		ctx, component.CommandType, task.Component.Name)
	if err != nil {
		return err
	}

	fn := cmd.Value.(component.Command).ExecuteFunc(
		strings.Split(task.Command, " "))
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

// Set project specific seeds
func (p *Project) seed(
	fn func(*core.Seeds), // callback for adding seeds
) {
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
	p.cleanup.Do(c)
}

// Close is called to clean up resources allocated by the project.
// This should be called and blocked on to gracefully stop the project.
func (p *Project) Close() (err error) {
	p.logger.Trace("closing project")

	return p.cleanup.Close()
}

// Saves the project to the db
func (p *Project) Save() error {
	p.m.Lock()
	defer p.m.Unlock()

	p.logger.Trace("saving project to db")

	// Remove the defined vms from finalized data to
	// prevent it from being used on subsequent runs
	if p.vagrantfile != nil {
		if err := p.vagrantfile.DeleteValue("vm", "__defined_vms"); err != nil {
			p.logger.Warn("failed to remove defined vms configuration before save",
				"error", err,
			)
		}

		val, err := p.vagrantfile.rootToStore()
		if err != nil {
			p.logger.Warn("failed to convert modified configuration for save",
				"error", err,
			)
		} else {
			p.project.Configuration.Finalized = val.Data
		}
	}

	result, err := p.Client().UpsertProject(p.ctx,
		&vagrant_server.UpsertProjectRequest{
			Project: p.project,
		},
	)
	if err != nil {
		p.logger.Trace("failed to save project",
			"error", err,
		)

		return err
	}

	p.project = result.Project

	return nil
}

func (p *Project) Components(ctx context.Context) ([]*Component, error) {
	return p.basis.components(ctx)
}

func (p *Project) scrubTargets() (err error) {
	var updated bool

	p.logger.Trace("scrubbing targets from project")

	for _, t := range p.project.Targets {
		resp, err := p.client.GetTarget(p.ctx,
			&vagrant_server.GetTargetRequest{
				Target: t,
			},
		)
		if err != nil {
			return err
		}

		if resp.Target.State == vagrant_server.Operation_NOT_CREATED ||
			resp.Target.State == vagrant_server.Operation_DESTROYED {
			p.logger.Trace("target does not exist, removing",
				"target", resp.Target,
			)
			// Try and load the target so we can destroy it. If that fails,
			// then we just delete it directly via the client
			var target *Target
			raw, ok := p.factory.cache.Fetch(resp.Target.ResourceId)
			if ok {
				target = raw.(*Target)
			} else {
				// NOTE: When loading the target, we do it manually and not
				// via the factory. This is because the factory will register
				// a closer on the project, and as this function will generally
				// be called from a project closer, we want to prevent getting
				// stuck in a deadlock.
				if target, err = NewTarget(
					WithProject(p),
					WithTargetRef(t),
				); err == nil {
					// Attach our logger to the target so it can customize it
					target.logger = p.logger
					if err = target.Init(); err != nil {
						target = nil
					}
				} else {
					target = nil
				}
			}

			if target == nil {
				p.logger.Trace("failed to load target for removal, manually deleting",
					"target", resp.Target,
				)
				_, err = p.client.DeleteTarget(p.ctx,
					&vagrant_server.DeleteTargetRequest{
						Target: t,
					},
				)
				if err != nil {
					return err
				}
			} else {
				err = target.Destroy()
				if err != nil {
					return err
				}
			}
			updated = true
		} else {
			p.logger.Trace("not scrubbing target, exists", "target", resp.Target)
		}
	}

	if updated {
		err = p.Reload()
	}

	p.logger.Trace("target scrubbing has been completed")
	return
}

// Initialize all targets for this project
func (p *Project) InitTargets() (err error) {
	p.logger.Trace("initializing targets defined within project")

	// Get list of targets this project knows about based
	// on the vagrantfile configuration
	names, err := p.vagrantfile.TargetNames()
	if err != nil {
		p.logger.Trace("failed to get target names",
			"error", err,
		)

		return
	}

	// We'll store the resource ids of the targets
	// defined in the vagrantfile here for reference
	// later
	current := map[string]struct{}{}

	p.logger.Trace("loading targets defined by vagrantfile",
		"targets", names,
	)

	// Use the factory to create or load the targets
	// so they are all valid in the database
	for _, name := range names {
		p.logger.Trace("loading new target from factory during init", "name", name)
		t, err := p.factory.NewTarget(
			WithTargetName(name),
			WithProject(p),
		)
		if err != nil {
			p.logger.Error("failed to load target from factory", "name", name)
			return err
		}
		p.logger.Trace("new target from factory during init", "target", t)
		current[t.target.ResourceId] = struct{}{}
	}

	return p.Reload()
}

// Reload the project data
func (p *Project) Reload() (err error) {
	p.m.Lock()
	defer p.m.Unlock()

	if p.project.ResourceId == "" {
		return status.Error(codes.NotFound, "project does not exist")
	}

	result, err := p.Client().FindProject(p.ctx,
		&vagrant_server.FindProjectRequest{
			Project: p.project,
		},
	)

	if err != nil {
		return
	}

	p.project = result.Project
	return
}

// Create a target within this project if it does not already exist
func (p *Project) createTarget(
	name string, // name of the target
) (*vagrant_server.Target, error) {
	result, err := p.Client().FindTarget(p.ctx,
		&vagrant_server.FindTargetRequest{
			Target: &vagrant_server.Target{
				Name:    name,
				Project: p.Ref().(*vagrant_plugin_sdk.Ref_Project),
			},
		},
	)
	// If we encountered any error except a not found, return it
	if err != nil && status.Code(err) != codes.NotFound {
		return nil, err
	}

	// If we have no error here, we have an existing result
	if err == nil {
		return result.Target, nil
	}

	// And if we are still here, create it
	resp, err := p.Client().UpsertTarget(p.ctx,
		&vagrant_server.UpsertTargetRequest{
			Target: &vagrant_server.Target{
				Name:    name,
				Project: p.Ref().(*vagrant_plugin_sdk.Ref_Project),
			},
		},
	)
	if err != nil {
		return nil, err
	}

	return resp.Target, nil
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
		p.project.Basis = b.Ref().(*vagrant_plugin_sdk.Ref_Basis)
		return
	}
}

func WithProjectDataDir(dir *datadir.Project) ProjectOption {
	return func(p *Project) (err error) {
		if dir == nil {
			return errors.New("directory value cannot be nil")
		}
		p.dir = dir
		return
	}
}

func WithProjectName(name string) ProjectOption {
	return func(p *Project) (err error) {
		if name == "" {
			return errors.New("name cannot be empty")
		}
		p.project.Name = name
		return
	}
}

// WithBasisRef is used to load or initialize the project
func WithProjectRef(r *vagrant_plugin_sdk.Ref_Project) ProjectOption {
	return func(p *Project) (err error) {
		// The ref value must be provided
		if r == nil {
			return errors.New("project reference cannot be nil")
		}
		if r.Name != "" {
			p.project.Name = r.Name
		}
		if r.Path != "" {
			p.project.Path = r.Path
		}
		if r.ResourceId != "" {
			p.project.ResourceId = r.ResourceId
		}
		if r.Basis != nil {
			p.project.Basis = r.Basis
		}

		return
	}
}

var _ core.Project = (*Project)(nil)
var _ Scope = (*Project)(nil)
