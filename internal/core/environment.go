package core

import (
	"context"
	"fmt"
	"os"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
)

const (
	currentSetupVersion = "1.5"
	defaultLocalData    = ".vagrant"
)

type Environment struct {
	logger hclog.Logger

	ServerAddr            string
	Cwd                   path.Path
	DataDir               *datadir.Basis
	VagrantfileName       string
	HomePath              path.Path
	LocalDataPath         path.Path
	TmpPath               path.Path
	AliasesPath           path.Path
	BoxesPath             path.Path
	GemsPath              path.Path
	DefaultPrivateKeyPath path.Path
}

type EnvironmentOption func(*Environment)

// NewEnvironment creates a new Environment with the given options.
func NewEnvironment(ctx context.Context, opts ...EnvironmentOption) (e *Environment, err error) {
	e = &Environment{
		logger: hclog.L(),
	}

	for _, opt := range opts {
		opt(e)
	}

	if e.HomePath == nil {
		return nil, fmt.Errorf("WithHomePath must be specified")
	}

	e.BoxesPath = e.HomePath.Join("boxes")
	e.TmpPath = e.HomePath.Join("tmp")
	e.DefaultPrivateKeyPath = e.HomePath.Join("insecure_private_key")
	// TODO:
	// e.GemsPath =

	if os.Getenv("VAGRANT_ALIAS_FILE") != "" {
		e.AliasesPath = path.NewPath(os.Getenv("VAGRANT_ALIAS_FILE"))
	} else {
		e.AliasesPath = e.HomePath.Join("aliases")
	}

	// Override vagrant cwd if required
	if os.Getenv("VAGRANT_CWD") != "" {
		e.Cwd = path.NewPath(os.Getenv("VAGRANT_CWD"))
	} else {
		cwd, err := path.NewPath(".").Abs()
		if err != nil {
			panic("cannot determine local directory")
		}
		e.Cwd = cwd
	}

	// Override vagrantfile name if required
	if os.Getenv("VAGRANT_VAGRANTFILE") != "" {
		e.VagrantfileName = os.Getenv("VAGRANT_VAGRANTFILE")
	} else {
		if e.VagrantfileName == "" {
			e.VagrantfileName = "Vagrantfile"
		}
	}

	// If we don't have a local data path set, lets do that now
	if e.LocalDataPath == nil {
		e.LocalDataPath = path.NewPath(defaultLocalData)
	}

	return
}

func WithHomePath(homePath path.Path) EnvironmentOption {
	return func(e *Environment) { e.HomePath = homePath }
}

func WithServerAddr(serverAddr string) EnvironmentOption {
	return func(e *Environment) { e.ServerAddr = serverAddr }
}

// TODO: finish implementation
