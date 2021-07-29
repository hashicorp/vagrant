package cli

import (
	"context"
	"errors"
	"io"
	"regexp"
	"strings"

	"github.com/DavidGamba/go-getoptions"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-multierror"

	"github.com/hashicorp/vagrant-plugin-sdk/helper/path"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/clicontext"
	clientpkg "github.com/hashicorp/vagrant/internal/client"
	"github.com/hashicorp/vagrant/internal/clierrors"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// baseCommand is embedded in all commands to provide common logic and data.
//
// The unexported values are not available until after Init is called. Some
// values are only available in certain circumstances, read the documentation
// for the field to determine if that is the case.
type baseCommand struct {
	// Ctx is the base context for the command. It is up to commands to
	// utilize this context so that cancellation works in a timely manner.
	Ctx context.Context

	// Log is the logger to use.
	Log hclog.Logger

	// LogOutput is the writer that Log points to. You SHOULD NOT use
	// this directly. We have access to this so you can use
	// hclog.OutputResettable if necessary.
	LogOutput io.Writer

	//---------------------------------------------------------------
	// The fields below are only available after calling Init.

	// cfg is the parsed configuration
	cfg *config.Config

	// UI is used to write to the CLI.
	ui terminal.UI

	// client for performing operations
	basis   *clientpkg.Basis
	project *clientpkg.Project
	targets []*clientpkg.Target

	// clientContext is set to the context information for the current
	// connection. This might not exist in the contextStorage yet if this
	// is from an env var or flags.
	clientContext *clicontext.Config

	// contextStorage is for CLI contexts.
	contextStorage *clicontext.Storage

	//---------------------------------------------------------------
	// Internal fields that should not be accessed directly

	// flagPlain is whether the output should be in plain mode.
	flagPlain bool

	// flagLabels are set via -label if flagSetOperation is set.
	flagLabels map[string]string

	// flagRemote is whether to execute using a remote runner or use
	// a local runner.
	flagRemote bool

	// flagRemoteSource are the remote data source overrides for jobs.
	flagRemoteSource map[string]string

	// flagBasis is the basis to work within.
	flagBasis string

	// flagMachine is the machine to target.
	flagTarget string

	// flagConnection contains manual flag-based connection info.
	flagConnection clicontext.Config

	// args that were present after parsing flags
	args []string

	// options passed in at the global level
	globalOptions []Option
}

// Close cleans up any resources that the command created. This should be
// defered by any CLI command that embeds baseCommand in the Run command.
func (c *baseCommand) Close() error {
	if closer, ok := c.ui.(io.Closer); ok && closer != nil {
		closer.Close()
	}

	if c.basis != nil {
		c.basis.Close()
	}

	return nil
}

func BaseCommand(ctx context.Context, log hclog.Logger, logOutput io.Writer, opts ...Option) (*baseCommand, error) {
	bc := &baseCommand{
		Ctx:       ctx,
		Log:       log,
		LogOutput: logOutput,
	}

	// Get just enough base configuration to
	// allow setting up our client connection
	c := &baseConfig{
		Client: true,
		Flags:  bc.flagSet(flagSetConnection, nil),
	}

	// Apply any options that were passed. These
	// should at least include the arguments so
	// we can extract the flags properly
	for _, opt := range opts {
		opt(c)
	}

	if c.UI == nil {
		c.UI = terminal.ConsoleUI(context.Background())
	}

	// Allow parser to not fail on unknown arguments
	c.Flags.SetUnknownMode(getoptions.Pass)
	if _, err := c.Flags.Parse(c.Args); err != nil {
		c.UI.Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return nil, err
	}

	// Setup our basis path
	homeConfigPath, err := paths.VagrantConfig()
	if err != nil {
		bc.ui.Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return nil, err
	}
	bc.Log.Debug("home configuration directory", "path", homeConfigPath.String())

	// Setup our base directory for context management
	contextStorage, err := clicontext.NewStorage(
		clicontext.WithDir(homeConfigPath.Join("context")))
	if err != nil {
		bc.ui.Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return nil, err
	}
	bc.contextStorage = contextStorage

	// We use our flag-based connection info if the user set an addr.
	var flagConnection *clicontext.Config
	if v := bc.flagConnection; v.Server.Address != "" {
		flagConnection = &v
	}

	// Get the context we'll use. The ordering here is purposeful and creates
	// the following precedence: (1) context (2) env (3) flags where the
	// later values override the former.

	connectOpts := []serverclient.ConnectOption{
		serverclient.FromContext(bc.contextStorage, ""),
		serverclient.FromEnv(),
		serverclient.FromContextConfig(flagConnection),
	}
	bc.clientContext, err = serverclient.ContextConfig(connectOpts...)
	if err != nil {
		return nil, err
	}

	// Start building our client options
	basisOpts := []clientpkg.Option{
		clientpkg.WithLogger(bc.Log.ResetNamed("vagrant.client")),
		clientpkg.WithClientConnect(connectOpts...),
		// clientpkg.WithBasis(
		// 	&vagrant_server.Basis{
		// 		Name: homeConfigPath.String(),
		// 		Path: homeConfigPath.String(),
		// 	},
		// ),
	}
	if !bc.flagRemote {
		basisOpts = append(basisOpts, clientpkg.WithLocal())
	}

	if bc.ui != nil {
		basisOpts = append(basisOpts, clientpkg.WithUI(bc.ui))
	}

	basis, err := clientpkg.New(context.Background(), basisOpts...)
	if err != nil {
		return nil, err
	}

	// Determine if we are in a project and setup if so
	cwd, err := path.NewPath(".").Abs()
	if err != nil {
		panic("cannot setup local directory")
	}
	if true { //} _, err := config.FindPath("", ""); err == nil {
		bc.project, err = basis.LoadProject(
			&vagrant_server.Project{
				Name:  cwd.Base().String(),
				Path:  cwd.String(),
				Basis: basis.Ref(),
			},
		)
		if err != nil {
			return nil, err
		}
	}

	bc.basis = basis

	return bc, err
}

// Init initializes the command by parsing flags, parsing the configuration,
// setting up the project, etc. You can control what is done by using the
// options.
//
// Init should be called FIRST within the Run function implementation. Many
// options will affect behavior of other functions that can be called later.
func (c *baseCommand) Init(opts ...Option) error {
	baseCfg := baseConfig{
		Config: true,
		Client: true,
	}

	for _, opt := range c.globalOptions {
		opt(&baseCfg)
	}

	for _, opt := range opts {
		opt(&baseCfg)
	}

	// Init our UI first so we can write output to the user immediately.
	ui := baseCfg.UI
	if ui == nil {
		ui = terminal.ConsoleUI(c.Ctx)
	}

	c.ui = ui

	// Parse flags
	remainingArgs, err := baseCfg.Flags.Parse(baseCfg.Args)
	if err != nil {
		c.ui.Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return err
	}
	c.args = remainingArgs

	// Reset the UI to plain if that was set
	if c.flagPlain {
		c.ui = terminal.NonInteractiveUI(c.Ctx)
	}

	// TODO(spox): re-enable custom basis
	// Set our basis reference if provided
	// if c.flagBasis != "" {
	// 	c.basis.SetRef(&vagrant_server.Ref_Basis{Name: c.flagBasis})
	// }

	// Parse the configuration
	c.cfg = &config.Config{}

	// If we have an app target requirement, we have to get it from the args
	// or the config.
	if baseCfg.TargetRequired && c.project != nil {
		// If we have args, attempt to extract there first.
		if len(c.args) > 0 {
			match := reTarget.FindStringSubmatch(c.args[0])
			if match != nil {
				// Set our machine
				t, err := c.project.LoadTarget(&vagrant_server.Target{
					Name:    match[1],
					Project: c.project.Ref(),
				})
				if err != nil {
					return err
				}
				c.targets = append(c.targets, t)

				// Shift the args
				c.args = c.args[1:]

				// Explicitly set remote
				c.flagRemote = true
			}
		}

		// If we didn't get our ref, then we need to load config
		if len(c.targets) == 0 {
			baseCfg.Config = true
		}
	}

	// If we're loading the config, then get it.
	if baseCfg.Config {
		cfg, err := c.initConfig(baseCfg.ConfigOptional)
		if err != nil {
			c.logError(c.Log, "failed to load configuration", err)
			return err
		}
		// vagrantfile, err := c.basis.ParseVagrantfile()
		// if err != nil {
		// 	c.logError(c.Log, "failed to parse vagrantfile", err)
		// 	return err
		// }
		// cfg.Project, err = cfg.LoadProject(vagrantfile, c.project.Ref())
		// if err != nil {
		// 	c.logError(c.Log, "failed to load project", err)
		// 	return err
		// }

		c.cfg = cfg
		if cfg != nil {
			// If we require an app target and we still haven't set it,
			// and the user provided it via the CLI, set it now. This code
			// path is only reached if it wasn't set via the args either
			// above.
			if c.flagTarget == "" {
				c.flagTarget = "default"
			}
			t, err := c.project.LoadTarget(&vagrant_server.Target{
				Name:    c.flagTarget,
				Project: c.project.Ref(),
			})

			if err != nil {
				return err
			}

			c.targets = append(c.targets, t)
		}
	}

	// Create our client
	// if baseCfg.Client {
	// 	var err error
	// 	c.basis, err = c.initClient()
	// 	if err != nil {
	// 		c.logError(c.Log, "failed to create client", err)
	// 		return err
	// 	}
	// }

	// Validate remote vs. local operations.
	if c.flagRemote && len(c.targets) == 0 {
		if c.cfg == nil || c.cfg.Runner == nil || !c.cfg.Runner.Enabled {
			err := errors.New(
				"The `-remote` flag was specified but remote operations are not supported\n" +
					"for this project.\n\n" +
					"Remote operations must be manually enabled by using setting the 'runner.enabled'\n" +
					"setting in your Vagrant configuration file. Please see the documentation\n" +
					"on this setting for more information.")
			c.logError(c.Log, "", err)
			return err
		}
	}

	// If this is a single app mode then make sure that we only have
	// one app or that we have an app target.
	if false && baseCfg.TargetRequired {
		if len(c.targets) == 0 {
			if len(c.cfg.Project.Targets) != 1 {
				c.ui.Output(errTargetModeSingle, terminal.WithErrorStyle())
				return ErrSentinel
			}

			if c.project == nil {
				c.project, err = c.basis.LoadProject(
					&vagrant_server.Project{
						Name:  c.cfg.Project.Location,
						Path:  c.cfg.Project.Location,
						Basis: c.basis.Ref(),
					},
				)
				if err != nil {
					return err
				}
			}

			target, err := c.project.LoadTarget(&vagrant_server.Target{
				Name:    c.cfg.Project.Targets[0].Name,
				Project: c.project.Ref(),
			})

			if err != nil {
				return err
			}

			c.targets = append(c.targets, target)
		}
	}

	return nil
}

type Tasker interface {
	UI() terminal.UI
	Task(context.Context, *vagrant_server.Job_RunOp) (*vagrant_server.Job_RunResult, error)
	//CreateTask() *vagrant_server.Task
}

// Do calls the callback based on the loaded scope. This automatically handles any
// parallelization, waiting, and error handling. Your code should be
// thread-safe.
//
// Based on the scope the callback may be executed multiple times. When scoped by
// machine, it will be run against each requested machine. When the scope is basis
// or project, it will only be run once.
//
// If any error is returned, the caller should just exit. The error handling
// including messaging to the user is handling by this function call.
//
// If you want to early exit all the running functions, you should use
// the callback closure properties to cancel the passed in context. This
// will stop any remaining callbacks and exit early.
func (c *baseCommand) Do(ctx context.Context, f func(context.Context, Tasker) error) (finalErr error) {
	// Start with checking if we are running in a machine based scope
	if len(c.targets) > 0 {
		for _, m := range c.targets {
			c.Log.Debug("running command on target", "target", m)
			// If the context has been canceled, then bail
			if err := ctx.Err(); err != nil {
				return err
			}

			if err := f(ctx, m); err != nil {
				if err != ErrSentinel {
					finalErr = multierror.Append(finalErr, err)
				}
			}
		}
		return
	}

	// Now we can check if this is project scoped
	if c.project != nil {
		finalErr = f(ctx, c.project)
		return
	}

	// And if we're still here, it's gotta be basis scoped
	return f(ctx, c.basis)
}

// logError logs an error and outputs it to the UI.
func (c *baseCommand) logError(log hclog.Logger, prefix string, err error) {
	if err == ErrSentinel {
		return
	}

	log.Error(prefix, "error", err)

	if prefix != "" {
		prefix += ": "
	}
	c.ui.Output("%s%s", prefix, err, terminal.WithErrorStyle())
}

// flagSet creates the flags for this command. The callback should be used
// to configure the set with your own custom options.
func (c *baseCommand) flagSet(bit flagSetBit, f func(*getoptions.GetOpt)) *getoptions.GetOpt {
	set := getoptions.New()
	set.BoolVar(
		&c.flagPlain,
		"plain",
		false,
		set.Description("Plain output: no colors, no animation."),
	)

	set.StringVar(
		&c.flagTarget,
		"target",
		"",
		set.Description("Target to apply. Certain commands require a single target for "+
			"Vagrant configurations with multiple apps. If you have a single target, "+
			"then this can be ignored."),
	)

	set.StringVar(
		&c.flagBasis,
		"basis",
		"default",
		set.Description("Basis to operate within."),
	)

	if bit&flagSetOperation != 0 {
		set.StringMapVar(
			&c.flagLabels,
			"label",
			1,
			MaxStringMapArgs,
			set.Description("Labels to set for this operation. Can be specified multiple times."),
		)

		set.BoolVar(
			&c.flagRemote,
			"remote",
			false,
			set.Description("True to use a remote runner to execute. This defaults to false \n"+
				"unless 'runner.default' is set in your configuration."),
		)

		set.StringMapVar(
			&c.flagRemoteSource,
			"remote-source",
			1,
			MaxStringMapArgs,
			set.Description("Override configurations for how remote runners source data. "+
				"This is specified to the data source type being used in your configuration. "+
				"This is used for example to set a specific Git ref to run against."),
		)
	}

	if bit&flagSetConnection != 0 {
		set.StringVar(
			&c.flagConnection.Server.Address,
			"server-addr",
			"",
			set.Description("Address for the server."),
		)

		set.BoolVar(
			&c.flagConnection.Server.Tls,
			"server-tls",
			true,
			set.Description("True if the server should be connected to via TLS."),
		)

		set.BoolVar(
			&c.flagConnection.Server.TlsSkipVerify,
			"server-tls-skip-verify",
			false,
			set.Description("True to skip verification of the TLS certificate advertised by the server."),
		)
	}

	if f != nil {
		// Configure our values
		f(set)
	}

	return set
}

// flagSetBit is used with baseCommand.flagSet
type flagSetBit uint

const (
	flagSetNone       flagSetBit = 1 << iota
	flagSetOperation             // shared flags for operations (build, deploy, etc)
	flagSetConnection            // shared flags for server connections
)

const MaxStringMapArgs int = 50

var (
	// ErrSentinel is a sentinel value that we can return from Init to force an exit.
	ErrSentinel = errors.New("error sentinel")

	errTargetModeSingle = strings.TrimSpace(`
This command requires a single targeted machine. You have multiple machines defined
so you can specify the machine to target using the "-machine" flag.
`)

	reTarget = regexp.MustCompile(`^(?P<machine>[-0-9A-Za-z_]+)$`)
)
