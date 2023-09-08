// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: BUSL-1.1

package core

import (
	"context"
	"fmt"
	"path/filepath"
	"reflect"
	"strings"
	"sync"

	"github.com/fatih/structs"
	"github.com/fatih/structtag"
	"github.com/hashicorp/go-argmapper"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/gohcl"
	"github.com/hashicorp/hcl/v2/hclsimple"
	"github.com/mitchellh/protostructure"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/config"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/types"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cacher"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/dynamic"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant-plugin-sdk/localizer"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// LoadLocation type defines the origin of a Vagrantfile. The
// higher the value of the LoadLocation, the higher the precedence
// when merging
type LoadLocation uint8

// DEFAULT_VM_NAME is the name that a target gets when none has been specified.
const DEFAULT_VM_NAME = "default"

const (
	VAGRANTFILE_BOX      LoadLocation = iota // Box
	VAGRANTFILE_BASIS                        // Basis
	VAGRANTFILE_PROJECT                      // Project
	VAGRANTFILE_TARGET                       // Target
	VAGRANTFILE_PROVIDER                     // Provider
)

// These are the locations which can be used for
// populating the root value in the vagrantfile
var ValidRootLocations = map[LoadLocation]struct{}{
	VAGRANTFILE_BASIS:   {},
	VAGRANTFILE_PROJECT: {},
	VAGRANTFILE_TARGET:  {},
}

// Registration entry for a config component
type registration struct {
	identifier       string                      // The identifier is the root key used in the Vagrantfile
	plugin           *plugin.Plugin              // Plugin that provides this config component
	set              bool                        // Flag to identify this configuration is in use
	subregistrations map[string]*subregistration // Configuration plugins used within this configuration
}

func (r *registration) String() string {
	return fmt.Sprintf("core.Vagrantfile.registration[identifier: %s, plugin %v, set: %v, subregistrations: %s]",
		r.identifier, r.plugin, r.set, r.subregistrations)
}

func (r *registration) hasSubs() bool {
	return len(r.subregistrations) > 0
}

// Register a config component as a subconfig
func (r *registration) sub(scope string, p *plugin.Plugin) error {
	if _, ok := r.subregistrations[scope]; !ok {
		r.subregistrations[scope] = &subregistration{
			scope:   scope,
			plugins: []*plugin.Plugin{p},
		}
		return nil
	}
	r.subregistrations[scope].plugins = append(
		r.subregistrations[scope].plugins, p,
	)

	return nil
}

// Registration entry for a config component that is using within
// other config components (providers, provisioners, etc.)
type subregistration struct {
	scope   string           // The scope is the sub-key used
	plugins []*plugin.Plugin // Plugin that provides this config component
}

func (r *subregistration) String() string {
	return fmt.Sprintf("core.Vagrantfile.subregistration[scope: %s, plugins: %v]", r.scope, r.plugins)
}

// Collection of config component registrations
type registrations map[string]*registration

// Initialize a new registration entry. This will create
// the entry without a plugin value set which is useful
// for adding subregistrations before toplevel registration
// has been created.
func (r registrations) init(n string) *registration {
	if v, ok := r[n]; ok {
		return v
	}
	r[n] = &registration{
		identifier:       n,
		subregistrations: map[string]*subregistration{},
	}

	return r[n]
}

// Register a config component
func (r registrations) register(n string, p *plugin.Plugin) error {
	if _, ok := r[n]; ok {
		return fmt.Errorf("namespace %s is already registered by plugin %s", n, p.Name)
	}
	r[n] = &registration{
		identifier:       n,
		plugin:           p,
		subregistrations: map[string]*subregistration{},
	}

	return nil
}

// Represents an individual Vagrantfile source
type source struct {
	base        *vagrant_server.Vagrantfile // proto representing the Vagrantfile
	finalized   *component.ConfigData       // raw configuration data after finalization
	unfinalized *component.ConfigData       // raw configuration data prior to finalization
	vagrantfile *config.Vagrantfile         // vagrantfile as processed
}

// And here's our Vagrantfile!
type Vagrantfile struct {
	cache         cacher.Cache                    // Cached used for storing target configs
	cleanup       cleanup.Cleanup                 // Cleanup tasks to run on close
	boxes         *BoxCollection                  // Box collection to utilize
	logger        hclog.Logger                    // Logger
	mappers       []*argmapper.Func               // Mappers
	factory       *Factory                        // Factory for target generation
	registrations registrations                   // Config plugin registrations
	root          *component.ConfigData           // Combined Vagrantfile config
	rubyClient    *serverclient.RubyVagrantClient // Client for the Ruby runtime
	sources       map[LoadLocation]*source        // Vagrantfile sources

	targetSource *vagrant_plugin_sdk.Ref_Project

	internal interface{} // Internal instance used for running maps
	m        sync.Mutex
}

func (v *Vagrantfile) String() string {
	return fmt.Sprintf("core.Vagrantfile[factory: %v, registrations: %s, sources: %v]",
		v.factory, v.registrations, v.sources)
}

// Create a new Vagrantfile instance
func NewVagrantfile(
	f *Factory,
	b *BoxCollection,
	m []*argmapper.Func, // Mappers to be used for type conversions
	l hclog.Logger, // Logger
) *Vagrantfile {
	var err error
	if m == nil {
		m, err = argmapper.NewFuncList(protomappers.All,
			argmapper.Logger(dynamic.Logger),
		)
		if err == nil {
			l.Error("failed to generate mapper functions",
				"error", err,
			)
			m = []*argmapper.Func{}
		}
	}
	v := &Vagrantfile{
		cache:         cacher.New(),
		cleanup:       cleanup.New(),
		boxes:         b,
		logger:        l.Named("vagrantfile"),
		mappers:       m,
		factory:       f,
		registrations: make(registrations),
		rubyClient:    f.plugins.RubyClient(),
		sources:       make(map[LoadLocation]*source),
	}
	int := plugin.NewInternal(
		f.plugins.LegacyBroker(),
		v.cache,
		v.cleanup,
		v.logger,
		v.mappers,
	)
	v.internal = int

	return v
}

// Get the source Vagrantfile proto for the configured location
func (v *Vagrantfile) GetSource(
	l LoadLocation, // Load location of the source
) (*vagrant_server.Vagrantfile, error) {
	s, ok := v.sources[l]
	if !ok {
		return nil, fmt.Errorf("no vagrantfile source for given location (%s)", l)
	}

	return s.base, nil
}

// Register a task to be performed on close
func (v *Vagrantfile) Closer(
	fn cleanup.CleanupFn, // cleanup task to perform
) {
	v.cleanup.Do(fn)
}

// Perform any registered closer tasks
func (v *Vagrantfile) Close() error {
	v.logger.Trace("closing vagrantfile")
	return v.cleanup.Close()
}

// Add a source Vagrantfile
func (v *Vagrantfile) Source(
	vf *vagrant_server.Vagrantfile, // vagrantfile source
	l LoadLocation, // location of the vagrantfile source
) error {
	v.m.Lock()
	defer v.m.Unlock()
	// If the configuration we are given is nil, ignore it
	if vf == nil {
		v.logger.Debug("vagrantfile is unset, not adding",
			"location", l.String(),
		)
		return nil
	}

	s, err := v.newSource(vf)
	if err != nil {
		v.logger.Debug("failed to generate new source",
			"location", l.String(),
			"error", err,
		)
		return err
	}

	v.sources[l] = s

	v.logger.Info("added new source to vagrantfile",
		"location", l.String(),
	)

	return nil
}

// Register configuration plugin
func (v *Vagrantfile) Register(
	info *component.ConfigRegistration, // plugin registration information
	p *plugin.Plugin, // plugin to register
) (err error) {
	v.m.Lock()
	defer v.m.Unlock()

	if info.Scope == "" {
		if v.registrations == nil {
			return fmt.Errorf("registrations are nil")
		}
		return v.registrations.register(info.Identifier, p)
	}

	r := v.registrations.init(info.Identifier)
	return r.sub(info.Scope, p)
}

// Initialize the Vagrantfile for use. This should be called
// after inital sources are added to populate the `root` value
// with the base merged and finalized configuration.
func (v *Vagrantfile) Init() (err error) {
	v.m.Lock()
	defer v.m.Unlock()

	v.logger.Debug("starting vagrantfile initialization",
		"sources", v.sources,
	)

	locations := []LoadLocation{}
	// Collect all the viable locations for the initial load
	for i := VAGRANTFILE_BOX; i <= VAGRANTFILE_PROVIDER; i++ {
		if _, ok := v.sources[i]; ok {
			locations = append(locations, i)
		}
	}

	// If our final location is finalized, and is a valid root location,
	// then we use that finalized value and return. What this effectively
	// allows is reusing a serialized Vagrantfile during a single run. Since
	// the Vagrantfile will be parsed during the init job, when the command
	// job runs, we won't need to redo the work.
	var s *source
	finalIdx := len(locations) - 1
	if finalIdx >= 0 {
		final := locations[finalIdx]
		if _, ok := ValidRootLocations[final]; ok {
			s = v.sources[final]
			if s.finalized != nil {
				v.logger.Info("setting vagrantfile root to finalized data and exiting",
					"data", hclog.Fmt("%#v", s.finalized),
				)
				v.root = s.finalized
				return
			}
		}
	}

	// Generate merged configuration data from locations
	// which are currently available
	var c *component.ConfigData
	if c, err = v.generate(locations...); err != nil {
		v.logger.Error("failed to generate initial vagrantfile configuration",
			"error", err,
		)
		return
	}

	// Finalize the generated config
	if v.root, err = v.finalize(c); err != nil {
		v.logger.Error("failed to finalize initial vagrantfile configuration",
			"error", err,
		)
		return
	}

	// Store the finalized configuration in the final source
	if s != nil {
		v.logger.Info("setting finalized into last vagrant source", "source", s)
		if err = v.setFinalized(s, v.root); err != nil {
			return
		}
	}

	v.logger.Debug("vagrantfile initialization complete")

	return
}

// Get the configuration for the given namespace
func (v *Vagrantfile) GetConfig(
	namespace string, // top level key in vagrantfile
) (*component.ConfigData, error) {
	raw, ok := v.root.Data[namespace]
	if !ok {
		v.logger.Trace("requested namespace does not exist",
			"namespace", namespace,
		)
		return nil, fmt.Errorf("no config defined for requested namespace (%s)", namespace)
	}
	c, ok := raw.(*component.ConfigData)
	if !ok {
		v.logger.Trace("requested namespace could not be cast to config data",
			"type", hclog.Fmt("%T", raw),
		)
		return nil, fmt.Errorf("invalid data type for requested namespace (%s)", namespace)
	}

	return c, nil
}

// Get the configuration for the given namespace and load
// it into the provided configuration struct
func (v *Vagrantfile) Get(
	namespace string, // top level key in vagrantfile
	config any, // pointer to configuration struct to populate
) error {
	return nil
}

// Get the primary target name
// TODO(spox): VM options support is not implemented yet, so this
//
//	will not return the correct value when default option
//	has been specified in the Vagrantfile
func (v *Vagrantfile) PrimaryTargetName() (n string, err error) {
	list, err := v.TargetNames()
	if err != nil {
		return
	}

	return list[0], nil
}

// Get list of target names defined within the Vagrantfile
func (v *Vagrantfile) TargetNames() (list []string, err error) {
	list = []string{}
	vm := v.getNamespace("vm")
	if vm == nil {
		v.logger.Trace("failed to get vm namespace from config")
		return
	}

	dvms, ok := vm["__defined_vm_keys"]
	if !ok {
		keys := []string{}
		for k, _ := range vm {
			keys = append(keys, k)
		}
		v.logger.Trace("failed to locate __defined_vm_keys in vm config",
			"keys", keys,
		)
		return
	}
	vmsList, ok := dvms.([]interface{})
	if !ok {
		v.logger.Trace("defined vm list is not a valid array type")

		return
	}

	list = make([]string, 0, len(vmsList))
	for _, val := range vmsList {
		if sym, ok := val.(types.Symbol); ok {
			list = append(list, string(sym))
		} else {
			v.logger.Trace("vm value is invalid type",
				"value", val,
				"type", hclog.Fmt("%T", val),
			)
		}
	}

	if len(list) == 0 {
		list = append(list, "default")
	}

	v.logger.Trace("full list of target names found",
		"targets", list,
	)

	return
}

// Load a new target instance
// TODO(spox): Probably add a name check against TargetNames
//
//	before doing the config load
func (v *Vagrantfile) Target(
	name, // Name of the target
	provider string, // Provider backing the target
) (target core.Target, err error) {
	v.logger.Info("doing lookup for target", "name", name)

	name, err = v.targetNameLookup(name)
	if err != nil {
		return nil, err
	}

	conf, err := v.TargetConfig(name, provider, true)
	if err != nil {
		return
	}

	opts := []TargetOption{
		WithTargetRef(
			&vagrant_plugin_sdk.Ref_Target{
				Name:    name,
				Project: v.targetSource,
			},
		),
		WithProvider(provider),
	}
	var vf *Vagrantfile

	if conf != nil {
		// Convert to actual Vagrantfile for target setup
		vf = conf.(*Vagrantfile)
		opts = append(opts, WithTargetVagrantfile(vf))
	}
	target, err = v.factory.NewTarget(opts...)
	if err != nil {
		return nil, err
	}
	rawTarget := target.(*Target)
	if provider != "" {
		rawTarget.target.Provider = provider
	}

	// Since the target config gives us a Vagrantfile which is
	// attached to the project, we need to clone it and attach
	// it to the target we loaded
	if vf != nil {
		tvf := vf.clone(name)

		if err = tvf.Init(); err != nil {
			return nil, err
		}
		tvf.logger = rawTarget.logger.Named("vagrantfile")
		rawTarget.vagrantfile = tvf

		if err = vf.Close(); err != nil {
			return nil, err
		}
	}

	return
}

// Generate a new Vagrantfile for the given target
// NOTE: This function may return a nil result without an error
// TODO(spox): Needs box configuration applied
func (v *Vagrantfile) TargetConfig(
	name, // name of the target
	provider string, // provider backing the target
	validateProvider bool, // validate the requested provider is supported
) (tv core.Vagrantfile, err error) {
	v.m.Lock()
	defer v.m.Unlock()

	name, err = v.targetNameLookup(name)
	if err != nil {
		return nil, err
	}

	if provider != "" {
		pp, err := v.factory.plugins.Find(provider, component.ProviderType)
		if err != nil {
			return nil, err
		}
		if validateProvider {
			usable, err := pp.Component.(core.Provider).Usable()
			if !usable {
				if errStatus, ok := status.FromError(err); ok {
					return nil, localizer.LocalizeStatusErr(
						"provider_not_usable",
						map[string]string{"Provider": provider, "Machine": name},
						errStatus,
						true,
					)
				}
			}
			if err != nil {
				return nil, err
			}
		}
	}

	cid := name + "+" + provider
	if cv := v.cache.Get(cid); cv != nil {
		return cv.(core.Vagrantfile), nil
	}

	subvm, err := v.GetValue("vm", "__defined_vms", name)
	if err != nil {
		// If we failed to get the subvm value, then we want to
		// just load the target directly so it can generate
		v.logger.Warn("failed to get target",
			"name", name,
			"error", err,
		)

		t, err := v.factory.NewTarget(
			WithTargetName(name),
			WithTargetProjectRef(v.targetSource),
		)
		if err != nil {
			if status.Code(err) != codes.NotFound {
				return nil, err
			}
			t, err = v.factory.NewTarget(
				WithTargetRef(
					&vagrant_plugin_sdk.Ref_Target{
						ResourceId: name,
					},
				),
			)
			if err != nil {
				return nil, err
			}
		}

		return t.vagrantfile, nil
	}

	if subvm == nil {
		v.logger.Error("failed to get subvm value",
			"name", name,
		)

		return nil, fmt.Errorf("empty value found for requested target")
	}
	v.logger.Info("running to proto on subvm value", "subvm", subvm)
	subvmProto, err := v.toProto(subvm)
	if err != nil {
		return nil, err
	}

	v.logger.Info("sending subvm to ruby for parsing", "subvm", subvmProto)
	resp, err := v.rubyClient.ParseVagrantfileSubvm(
		subvmProto.(*vagrant_plugin_sdk.Config_RawRubyValue),
	)

	if err != nil {
		v.logger.Error("failed to process target configuration",
			"response", resp,
			"error", err,
		)

		return nil, err
	}

	v.logger.Info("subvm configuration generated for target",
		"target", name,
		"config", resp,
	)

	newV := v.clone(name)
	err = newV.Source(
		&vagrant_server.Vagrantfile{
			Unfinalized: resp,
		},
		VAGRANTFILE_TARGET,
	)

	if err != nil {
		return nil, fmt.Errorf("failed to add target config source: %w", err)
	}

	if provider != "" {
		resp, err = v.rubyClient.ParseVagrantfileProvider(provider,
			subvmProto.(*vagrant_plugin_sdk.Config_RawRubyValue),
		)
		if err != nil {
			return nil, err
		}
		err = newV.Source(
			&vagrant_server.Vagrantfile{
				Unfinalized: resp,
			},
			VAGRANTFILE_PROVIDER,
		)
		if err != nil {
			return nil, fmt.Errorf("failed to add provider config source: %w", err)
		}
	}

	if err = newV.Init(); err != nil {
		return nil, fmt.Errorf("failed to init target config vagrantfile: %w", err)
	}

	vmRaw, ok := newV.root.Data["vm"]
	if !ok {
		return nil, fmt.Errorf("failed to get vm for delete modification")
	}
	vm, ok := vmRaw.(*component.ConfigData)
	if !ok {
		return nil, fmt.Errorf("failed to cast vm to expected map type (%T)", vmRaw)
	}
	delete(vm.Data, "__defined_vms")

	v.cache.Register(cid, newV)

	return newV, nil
}

func (v *Vagrantfile) DeleteValue(
	path ...string,
) error {
	if len(path) < 2 {
		return fmt.Errorf("cannot delete namespace")
	}

	toDelete := path[len(path)-1]
	path = path[0 : len(path)-1]

	val, err := v.GetValue(path...)
	if err != nil {
		return err
	}
	switch m := val.(type) {
	case map[interface{}]interface{}:
		delete(m, toDelete)
	case map[string]interface{}:
		delete(m, toDelete)
	default:
		return fmt.Errorf("cannot delete value, invalid container type (%T)", val)
	}
	return nil
}

// Attempts to extract configuration information
// located at the given path
func (v *Vagrantfile) GetValue(
	path ...string, // path to configuration value
) (interface{}, error) {
	if len(path) == 0 {
		return nil, fmt.Errorf("no lookup path provided")
	}
	var ok bool
	var result interface{}
	// Error will always be a failed path lookup so populate it now
	err := fmt.Errorf("failed to locate value at given path (%#v)", path)

	// First item in the path is going to be our namespace
	// in the root configuration
	result = v.getNamespace(path[0])
	if result == nil {
		v.logger.Warn("failed to get namespace for value fetch",
			"namespace", path[0],
		)
		return nil, err
	}

	// Since we already used out first path value above
	// be sure we start our loop from 1
	for i := 1; i < len(path); i++ {
		switch m := result.(type) {
		case map[string]interface{}:
			if result, ok = m[path[i]]; ok {
				continue
			}
			v.logger.Warn("get value lookup failed",
				"keys", path,
				"current-key", path[i],
				"type", "map[string]interface{}",
			)
			return nil, err
		case map[interface{}]interface{}:
			found := false
			for key, val := range m {
				if strKey, ok := key.(string); ok && strKey == path[i] {
					found = true
					result = val
					break
				}
				if symKey, ok := key.(types.Symbol); ok && string(symKey) == path[i] {
					found = true
					result = val
					break
				}
			}
			if found {
				continue
			}

			v.logger.Warn("get value lookup failed",
				"keys", path,
				"current-key", path[i],
				"type", "map[interface{}]interface{}",
			)

			return nil, err
		case *component.ConfigData:
			if result, ok = m.Data[path[i]]; ok {
				continue
			}
			v.logger.Warn("get value lookup failed",
				"keys", path,
				"current-key", path[i],
				"type", "ConfigData",
			)

			return nil, err
		case *types.RawRubyValue:
			if result, ok = m.Data[path[i]]; ok {
				continue
			}
			v.logger.Warn("get value lookup failed",
				"keys", path,
				"current-key", path[i],
				"type", "RawRubyValue",
			)

			return nil, err
		default:
			v.logger.Warn("get value lookup failed",
				"keys", path,
				"current-key", path[i],
				"type", "no-match",
			)

			return nil, err
		}

	}

	return result, nil
}

// Returns the configuration of a specific namespace
// in the root configuration.
func (v *Vagrantfile) getNamespace(
	n string, // namespace
) map[string]interface{} {
	v.logger.Trace("getting requested namespace",
		"namespace", n,
		"self", v,
	)
	raw, ok := v.root.Data[n]
	if !ok {
		v.logger.Trace("requested namespace does not exist",
			"namespace", n,
		)
		return nil
	}
	c, ok := raw.(*component.ConfigData)
	if !ok {
		v.logger.Trace("requested namespace could not be cast to config data",
			"type", hclog.Fmt("%T", raw),
		)
		return nil
	}
	v.logger.Trace("returning data for requested namespace",
		"namespace", n,
		"type", hclog.Fmt("%T", c.Data),
	)
	return c.Data
}

// Converts the current root value into proto for storing in the origin
func (v *Vagrantfile) rootToStore() (*vagrant_plugin_sdk.Args_ConfigData, error) {
	raw, err := dynamic.Map(
		v.root,
		(**vagrant_plugin_sdk.Args_ConfigData)(nil),
		argmapper.ConverterFunc(v.mappers...),
		argmapper.Typed(
			context.Background(),
			v.logger,
			plugin.Internal(v.logger, v.mappers),
		),
	)
	if err != nil {
		return nil, err
	}

	return raw.(*vagrant_plugin_sdk.Args_ConfigData), nil
}

// Create a new source instance from a given Vagrantfile.
// This will handle preloading any data which is available.
func (v *Vagrantfile) newSource(
	f *vagrant_server.Vagrantfile, // backing Vagrantfile proto for source
) (s *source, err error) {
	s = &source{
		base:        f,
		unfinalized: &component.ConfigData{},
	}

	// Start with loading the Vagrantfile if it hasn't
	// yet been loaded
	if s.base.Unfinalized == nil {
		if err := v.loadVagrantfile(s); err != nil {
			return nil, err
		}
	}

	if s.unfinalized == nil {
		// First we need to unpack the unfinalized data.
		if s.unfinalized, err = v.generateConfig(f.Unfinalized); err != nil {
			return
		}
	}

	// Next, if we have finalized data already set, just restore it
	// and be done.
	if f.Finalized != nil {
		s.finalized, err = v.generateConfig(f.Finalized)
		return
	}

	return s, nil
}

func (v *Vagrantfile) loadVagrantfile(
	source *source,
) error {
	var err error

	if source.base.Path == nil {
		return nil
	}

	// Set the format and load the file based on extension
	switch filepath.Ext(source.base.Path.Path) {
	case ".hcl":
		source.base.Format = vagrant_server.Vagrantfile_HCL
		if err = v.parseHCL(source); err != nil {
			return err
		}
		// Need to load and encode from here. Thoughts about protostructure and
		// if we should be treating hcl processed config differently
	case ".json":
		source.base.Format = vagrant_server.Vagrantfile_JSON
		if err = v.parseHCL(source); err != nil {
			return err
		}
	default:
		source.base.Format = vagrant_server.Vagrantfile_RUBY
		source.base.Unfinalized, err = v.rubyClient.ParseVagrantfile(source.base.Path.Path)
		source.unfinalized, err = v.generateConfig(source.base.Unfinalized)
		if err != nil {
			return err
		}
	}

	return nil
}

func (v *Vagrantfile) parseHCL(source *source) error {
	if source == nil {
		panic("vagrantfile source is nil")
	}
	target := &config.Vagrantfile{}

	// This handles loading native configuration
	err := hclsimple.DecodeFile(source.base.Path.Path, nil, target)
	if err != nil {
		v.logger.Error("failed to decode vagrantfile", "path", source.base.Path.Path, "error", err)
		return err
	}

	if source.unfinalized == nil {
		source.unfinalized = &component.ConfigData{}
	}
	source.unfinalized.Source = structs.Name(target)
	source.unfinalized.Data = map[string]interface{}{}
	// Serialize all non-plugin configuration values/namespaces
	fields := structs.Fields(target)
	for _, field := range fields {
		// TODO(spox): This is just implemented enough to get things
		// working. It needs to be reimplemented with helpers and all
		// that stuff.

		// if the field is the body content or remaining content after
		// being parsed, ignore it
		tags, err := structtag.Parse(`hcl:"` + field.Tag("hcl") + `"`)
		if err != nil {
			return err
		}
		tag, err := tags.Get("hcl")
		if err != nil {
			return err
		}
		skip := false
		for _, opt := range tag.Options {
			if opt == "remain" || opt == "body" {
				skip = true
			}
		}
		if skip {
			continue
		}

		// If there is no field name, or if the value is empty
		// just ignore it
		n := field.Name()
		np := strings.Split(field.Tag("hcl"), ",")
		if len(np) > 0 {
			n = np[0]
		}
		if n == "" {
			continue
		}

		val := field.Value()
		if field.IsZero() {
			val = &component.ConfigData{Data: map[string]any{}}
		}
		rval := reflect.ValueOf(val)

		// If the value is a struct, convert it to a map before storing
		if rval.Kind() == reflect.Struct || (rval.Kind() == reflect.Pointer && rval.Elem().Kind() == reflect.Struct) {
			val = &component.ConfigData{
				Source: structs.Name(val),
				Data:   structs.Map(val),
			}
		}
		source.unfinalized.Data[n] = val
	}

	// Now load all configuration which has registrations
	for namespace, registration := range v.registrations {
		// If no plugin is attached to registration, skip
		if registration.plugin == nil {
			continue
		}

		// Not handling subregistrations yet
		if registration.hasSubs() {
			continue
		}

		config, err := v.componentForKey(namespace)
		if err != nil {
			v.logger.Error("failed to dispense config plugin", "namespace", namespace, "error", err)
			return err
		}

		configTarget, err := config.Struct()
		if err != nil {
			v.logger.Error("failed to receive config structure", "namespace", namespace)
			return err
		}

		// If the struct value is a boolean, then the plugin is Ruby based. Take any configuration
		// that is currently defined (would have been populated via HCL file) and ship it to the
		// plugin to attempt to initialize itself with the existing data.
		//
		// TODO(spox): the data structure generated should use the hcl tag name as the key which
		// should match up better with the expected ruby configs
		if _, ok := configTarget.(bool); ok {
			vc := structs.New(target)

			// Find the configuration data for the current namespace
			var field *structs.Field
			for _, f := range vc.Fields() {
				t := f.Tag("hcl")
				np := strings.Split(t, ",")
				if len(np) < 1 {
					break
				}
				n := np[0]
				if n == namespace {
					field = f
					break
				}
			}

			var data map[string]any

			// If no field was found for namespace, or the value is empty, skip
			if field == nil || field.IsZero() {
				data = map[string]any{}
			} else {
				data = structs.Map(field.Value())
			}

			cd, err := config.Init(&component.ConfigData{Data: data})
			if err != nil {
				v.logger.Error("ruby config init failed", "error", err)
				return err
			}
			source.unfinalized.Data[namespace] = cd

			v.logger.Trace("stored unfinalized configuration data", "namespace", namespace, "value", cd)
			continue
		}

		v.logger.Trace("config structure received", "namespace", namespace, "struct", hclog.Fmt("%#v", configTarget))

		// A protostructure.Struct value is expected to build the configuration structure
		cs, ok := configTarget.(*protostructure.Struct)
		if !ok {
			v.logger.Error("config value is not protostructure.Struct", "namespace", namespace,
				"type", hclog.Fmt("%T", configTarget))
			return fmt.Errorf("invalid configuration type received %T", configTarget)
		}

		// Create the configuration structure
		configStruct, err := protostructure.New(cs)
		if err != nil {
			return err
		}

		// Build a struct which contains the configuration structure
		// so the Vagrantfile contents can be decoded into it
		wrapStructType := reflect.StructOf(
			[]reflect.StructField{
				{
					Name: "Remain",
					Type: reflect.TypeOf((*hcl.Body)(nil)).Elem(),
					Tag:  reflect.StructTag(`hcl:",remain"`),
				},
				{
					Name: "Content",
					Type: reflect.TypeOf(configStruct),
					Tag:  reflect.StructTag(fmt.Sprintf(`hcl:"%s,block"`, namespace)),
				},
			},
		)
		wrapStruct := reflect.New(wrapStructType)

		// Decode the Vagrantfile into the new wrapper
		diag := gohcl.DecodeBody(target.Remain, nil, wrapStruct.Interface())
		if diag.HasErrors() {
			return fmt.Errorf("failed to load config namespace %s: %s", namespace, diag.Error())
		}

		// Extract the decoded configuration
		str := structs.New(wrapStruct.Interface())
		f, ok := str.FieldOk("Content")
		if !ok {
			v.logger.Debug("missing 'Content' field in wrapper struct", "wrapper", wrapStruct.Interface())
			return fmt.Errorf("unexpected missing data during Vagrantfile decoding")
		}

		decodedConfig := f.Value()
		v.logger.Trace("configuration value decoded", "namespace", namespace, "config", decodedConfig)

		// Use reflect to do a proper nil check since interface
		// will be typed
		if reflect.ValueOf(decodedConfig).IsNil() {
			v.logger.Debug("decoded configuration was nil, continuing...", "namespace", namespace)
			continue
		}

		// Convert the configuration value into a map and store in the unfinalized
		// data for the plugin's namespace
		decodedMap := structs.Map(decodedConfig)
		source.unfinalized.Data[namespace] = &component.ConfigData{Data: decodedMap}

		v.logger.Trace("stored unfinalized configuration data", "namespace", namespace, "value", decodedMap)
	}

	return nil
}

// Finalize all configuration held within the provided
// config data. This assumes the given config data is
// the top level, with each key being the namespace
// for a given config plugin
func (v *Vagrantfile) finalize(
	conf *component.ConfigData, // root configuration data
) (result *component.ConfigData, err error) {
	result = &component.ConfigData{
		Data: make(map[string]interface{}),
	}
	var c core.Config
	var r *component.ConfigData
	seen := map[string]struct{}{}
	for n, val := range conf.Data {
		seen[n] = struct{}{}
		reg, ok := v.registrations[n]
		if !ok {
			v.logger.Warn("no plugin registered", "namespace", n)
			continue
		}
		v.logger.Trace("starting finalization", "namespace", n)
		// if no plugin attached, skip
		if reg.plugin == nil {
			v.logger.Warn("missing plugin registration", "namespace", n)
			continue
		}
		var data *component.ConfigData
		data, ok = val.(*component.ConfigData)
		if !ok {
			v.logger.Error("invalid data for namespace", "type", hclog.Fmt("%T", val))
			return nil, fmt.Errorf("invalid data encountered in '%s' namespace", n)
		}

		v.logger.Trace("finalizing", "namespace", n, "data", data)

		if c, err = v.componentForKey(n); err != nil {
			return nil, err
		}

		if r, err = c.Finalize(data); err != nil {
			return nil, err
		}

		v.logger.Trace("finalized", "namespace", n, "data", r)

		result.Data[n] = r
	}

	for n, reg := range v.registrations {
		if _, ok := result.Data[n]; ok {
			continue
		}
		if reg.plugin == nil {
			v.logger.Warn("missing plugin registration", "namespace", n)
			continue
		}
		if c, err = v.componentForKey(n); err != nil {
			return nil, err
		}
		if result.Data[n], err = c.Finalize(&component.ConfigData{}); err != nil {
			return nil, err
		}
	}

	v.logger.Trace("configuration data finalization is now complete")

	return
}

// Set the finalized value for the given source. This
// will convert the finalized data to proto and update
// the backing Vagrantfile proto.
func (v *Vagrantfile) setFinalized(
	s *source, // source to update
	f *component.ConfigData, // finalized data
) error {
	s.finalized = f

	raw, err := dynamic.Map(
		s.finalized.Data,
		(**vagrant_plugin_sdk.Args_Hash)(nil),
		argmapper.ConverterFunc(v.mappers...),
		argmapper.Typed(
			context.Background(),
			v.logger,
			plugin.Internal(v.logger, v.mappers),
		),
	)
	if err != nil {
		v.logger.Error("failed to convert data into finalized proto value")
		return err
	}

	s.base.Finalized = raw.(*vagrant_plugin_sdk.Args_Hash)

	return nil
}

// Generate a config data instance by merging all unfinalized
// data from each source that is requested. The result will
// be the unfinalized result of all merged configuration.
func (v *Vagrantfile) generate(
	locs ...LoadLocation, // order of sources to load
) (c *component.ConfigData, err error) {
	if len(locs) == 0 {
		return &component.ConfigData{Data: map[string]interface{}{}}, nil
	}

	c = v.sources[locs[0]].unfinalized

	for idx := 1; idx < len(locs); idx++ {
		i := locs[idx]
		v.logger.Trace("starting vagrantfile merge",
			"location", i.String(),
		)
		s, ok := v.sources[i]
		if !ok {
			v.logger.Warn("no vagrantfile set for location",
				"location", i.String(),
			)
			continue
		}
		if c == nil {
			v.logger.Trace("config unset, using location as base",
				"location", i.String(),
			)
			c = s.unfinalized
			continue
		}
		if c, err = v.merge(c, s.unfinalized); err != nil {
			v.logger.Trace("failed to merge vagrantfile",
				"location", i.String(),
				"error", err,
			)
			return
		}
		v.logger.Trace("completed vagrantfile merge",
			"location", i.String(),
		)
	}

	return
}

// Convert a proto hash into config data
func (v *Vagrantfile) generateConfig(
	value *vagrant_plugin_sdk.Args_Hash,
) (*component.ConfigData, error) {
	raw, err := dynamic.Map(
		&vagrant_plugin_sdk.Args_ConfigData{Data: value},
		(**component.ConfigData)(nil),
		argmapper.ConverterFunc(v.mappers...),
		argmapper.Typed(
			context.Background(),
			v.logger,
			v.internal,
		),
	)
	if err != nil {
		return nil, err
	}

	return raw.(*component.ConfigData), nil
}

// Get the configuration component for the given namespace
func (v *Vagrantfile) componentForKey(
	namespace string, // namespace config component is registered under
) (core.Config, error) {
	reg := v.registrations[namespace]
	if reg == nil || reg.plugin == nil {
		return nil, fmt.Errorf("no plugin set for config namespace '%s'", namespace)
	}
	c, err := reg.plugin.Component(component.ConfigType)
	if err != nil {
		return nil, err
	}
	return c.(core.Config), nil
}

// Merge two config data instances
func (v *Vagrantfile) merge(
	base, // initial config data
	overlay *component.ConfigData, // config data to merge into base
) (*component.ConfigData, error) {
	result := &component.ConfigData{
		Data: make(map[string]interface{}),
	}

	// Collect all the keys we have available
	keys := map[string]struct{}{}
	for k, _ := range base.Data {
		keys[k] = struct{}{}
	}
	for k, _ := range overlay.Data {
		keys[k] = struct{}{}
	}

	for k, _ := range keys {
		c, err := v.componentForKey(k)
		if err != nil {
			v.logger.Debug("no config component for namespace, skipping", "namespace", k)
		}
		rawBase, okBase := base.Data[k]
		rawOverlay, okOverlay := overlay.Data[k]

		if okBase && !okOverlay {
			result.Data[k] = rawBase
			v.logger.Debug("only base value available, no merge performed",
				"namespace", k, "config", rawBase,
			)
			continue
		}

		if !okBase && okOverlay {
			result.Data[k] = rawOverlay
			v.logger.Debug("only overlay value available, no merge performed",
				"namespace", k, "config", rawOverlay,
			)
			continue
		}

		if c == nil {
			result.Data[k] = rawOverlay
			v.logger.Debug("no component for namespace, applying overlay directly",
				"namespace", k, "config", rawOverlay,
			)
			continue
		}

		var ok bool
		var valBase, valOverlay *component.ConfigData
		valBase, ok = rawBase.(*component.ConfigData)
		if !ok {
			return nil, fmt.Errorf("bad value type for merge %T", rawBase)
		}
		valOverlay, ok = rawOverlay.(*component.ConfigData)
		if !ok {
			return nil, fmt.Errorf("bad value type for merge %T", rawOverlay)
		}

		v.logger.Debug("merging values",
			"namespace", k,
			"base", valBase,
			"overlay", valOverlay,
		)

		r, err := c.Merge(valBase, valOverlay)
		if err != nil {
			return nil, err
		}
		result.Data[k] = r
	}

	return result, nil
}

// Create a clone of the current Vagrantfile
func (v *Vagrantfile) clone(name string) *Vagrantfile {
	reg := make(registrations, len(v.registrations))
	for k, v := range v.registrations {
		reg[k] = v
	}
	srcs := make(map[LoadLocation]*source, len(v.sources))
	for k, v := range v.sources {
		srcs[k] = v
	}
	newV := &Vagrantfile{
		boxes:         v.boxes,
		cache:         v.cache,
		cleanup:       cleanup.New(),
		factory:       v.factory,
		internal:      v.internal,
		logger:        v.logger.Named(name),
		mappers:       v.mappers,
		registrations: reg,
		rubyClient:    v.rubyClient,
		sources:       srcs,
		targetSource:  v.targetSource,
	}

	v.Closer(func() error { return newV.Close() })

	int := plugin.NewInternal(
		newV.factory.plugins.LegacyBroker(),
		newV.factory.cache,
		newV.cleanup,
		newV.logger,
		newV.mappers,
	)
	v.internal = int

	return newV
}

// Convert value to proto
func (v *Vagrantfile) toProto(
	value interface{},
) (proto.Message, error) {
	raw, err := dynamic.Map(
		value,
		(*proto.Message)(nil),
		argmapper.ConverterFunc(v.mappers...),
		argmapper.Typed(
			context.Background(),
			v.logger,
			v.internal,
		),
	)
	if err != nil {
		return nil, err
	}

	return raw.(proto.Message), nil
}

// Lookup target by name or resource id and return
// the target's name.
func (v *Vagrantfile) targetNameLookup(
	nameOrId string, // target name or resource id
) (string, error) {
	if cname, ok := v.cache.Fetch("lookup" + nameOrId); ok {
		return cname.(string), nil
	}

	// Run a lookup first to verify if this target actually exists. If it does,
	// then request it.
	resp, err := v.factory.client.FindTarget(v.factory.ctx,
		&vagrant_server.FindTargetRequest{
			Target: &vagrant_server.Target{
				Name:       nameOrId,
				ResourceId: nameOrId,
				Project:    v.targetSource,
			},
		},
	)
	if err != nil {
		// When we are in Basis-only mode (VAGRANT_CWD does not have a
		// Vagrantfile), legacy Vagrant still expects to be able to retrieve config
		// for the default vm in order to successfully bootstrap its
		// Vagrant::Environment. In order to retain that behavior, we allow the
		// DEFAULT_VM_NAME to pass through successfully even when no targets
		// exist. Note we are specifically skipping the cache registration
		// below for this short circuit - we only want to do that when a target
		// exists.
		if s := status.Convert(err); s.Code() == codes.NotFound && nameOrId == DEFAULT_VM_NAME {
			v.logger.Info("ignoring target not found error for DEFAULT_VM_NAME")
			return DEFAULT_VM_NAME, nil
		}
		return "", err
	}

	// Register lookups in the local cache
	v.cache.Register(
		fmt.Sprintf("lookup+%s", resp.Target.Name),
		resp.Target.Name,
	)

	v.cache.Register(
		fmt.Sprintf("lookup+%s", resp.Target.ResourceId),
		resp.Target.Name,
	)

	return resp.Target.Name, nil
}

func (v *Vagrantfile) loadToRoot(
	value *vagrant_plugin_sdk.Args_ConfigData,
) error {
	raw, err := dynamic.Map(
		value,
		(**component.ConfigData)(nil),
		argmapper.ConverterFunc(v.mappers...),
		argmapper.Typed(
			context.Background(),
			v.logger,
			v.internal,
		),
	)
	if err != nil {
		return err
	}
	v.root = raw.(*component.ConfigData)
	return nil
}

// Get option value from config map. Since keys in the config
// can be either string or types.Symbol, this helper function
// will check for either type being set
func getOptionValue(
	name string, // name of option
	options map[interface{}]interface{}, // options map from config
) (interface{}, bool) {
	var key interface{}
	key = name
	result, ok := options[key]
	if ok {
		return result, true
	}
	key = types.Symbol(name)
	result, ok = options[key]
	if ok {
		return result, true
	}

	return nil, false
}

// Option values from the config which are expected to be string
// values may be a string or types.Symbol. This helper function
// will take the value and convert it into a string if possible.
func optionToString(
	opt interface{}, // value to convert
) (result string, err error) {
	result, ok := opt.(string)
	if ok {
		return
	}

	sym, ok := opt.(types.Symbol)
	if !ok {
		return result, fmt.Errorf("option value is not string type (%T)", opt)
	}
	result = string(sym)

	return
}

func structToMap(in any) map[string]any {
	new := structs.Map(in)
	for key, _ := range new {
		val := new[key]
		rval := reflect.ValueOf(val)
		if rval.Kind() == reflect.Struct || (rval.Kind() == reflect.Pointer && rval.Elem().Kind() == reflect.Struct) {
			new[key] = structToMap(val)
		}
	}

	return new
}

var _ core.Vagrantfile = (*Vagrantfile)(nil)
