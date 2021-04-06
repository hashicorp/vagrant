package config

import (
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclsimple"

	"github.com/hashicorp/vagrant/internal/pkg/defaults"
)

// Config is the core configuration
// TODO(spox): We need to do the whole merging thing
//             with the config and access things directly
//             via the Config, not the Basis or Project
type Config struct {
	Runner *Runner           `hcl:"runner,block" default:"{}"`
	Labels map[string]string `hcl:"labels,optional"`

	Basis   *Basis
	Project *Project

	Plugin   []*Plugin
	pathData map[string]string
	ctx      *hcl.EvalContext
}

// Runner is the configuration for supporting runners in this project.
type Runner struct {
	// Enabled is whether or not runners are enabled. If this is false
	// then the "-remote" flag will not work.
	Enabled bool

	// DataSource is the default data source when a remote job is queued.
	DataSource *DataSource
}

// DataSource configures the data source for the runner.
type DataSource struct {
	Type string
	Body hcl.Body `hcl:",remain"`
}

// Load loads the configuration file from the given path.
func Load(path string, pwd string) (*Config, error) {
	// We require an absolute path for the path so we can set the path vars
	if path != "" && !filepath.IsAbs(path) {
		var err error
		path, err = filepath.Abs(path)
		if err != nil {
			return nil, err
		}
	}

	// If we have no pwd, then create a temporary directory
	if pwd == "" {
		td, err := ioutil.TempDir("", "vagrant-config")
		if err != nil {
			return nil, err
		}
		defer os.RemoveAll(td)
		pwd = td
	}

	// Setup our initial variable set
	pathData := map[string]string{
		"pwd":       pwd,
		"basisfile": path,
	}

	// Decode
	var cfg Config
	// Build our context
	ctx := EvalContext(nil, pwd).NewChild()
	addPathValue(ctx, pathData)

	// Decode
	if err := hclsimple.DecodeFile(path, ctx, &cfg); err != nil {
		return nil, err
	}
	if err := defaults.Set(&cfg); err != nil {
		return nil, err
	}

	return &cfg, nil
}

// Load a project from a configuration file (Vagrantfile)
// func (c *Config) LoadProject(vagrantfile *vagrant_server.Vagrantfile, projectRef *vagrant_server.Ref_Project) (*Project, error) {
// 	// We require an absolute path for the path so we can set the path vars
// 	// if !filepath.IsAbs(path) {
// 	// 	var err error
// 	// 	path, err = filepath.Abs(path)
// 	// 	if err != nil {
// 	// 		return nil, err
// 	// 	}
// 	// }

// 	// // If we have no pwd, then use pwd from basis config
// 	// if pwd == "" {
// 	// 	pwd = c.pathData["pwd"]
// 	// }
// 	// // Setup our initial variable set
// 	// pathData := map[string]string{
// 	// 	"pwd":         pwd,
// 	// 	"project":     filepath.Dir(path),
// 	// 	"vagrantfile": path,
// 	// }

// 	// Decode
// 	// var cfg Project
// 	// cfg.Location = filepath.Dir(path)

// 	machines := []*Machine{}
// 	for _, el := range vagrantfile.MachineConfigs {
// 		machines = append(machines, &Machine{Name: el.Name, Box: el.Box})
// 	}
// 	communicators := []*Communicator{}
// 	for _, el := range vagrantfile.Communicators {
// 		communicators = append(communicators, &Communicator{Name: el.Name})
// 	}

// 	return &Project{
// 		Location:      filepath.Dir(vagrantfile.Path),
// 		Vagrant:       &Vagrant{},
// 		Machines:      machines,
// 		Communicators: communicators,
// 		path:          filepath.Dir(vagrantfile.Path),
// 		config:        c,
// 		ref:           projectRef,
// 	}, nil
// }
