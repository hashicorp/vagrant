package cli

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"regexp"
	"strconv"
	"strings"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/helper/paths"
	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/cleanup"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/clicontext"
	"github.com/hashicorp/vagrant/internal/client"
	clientpkg "github.com/hashicorp/vagrant/internal/client"
	"github.com/hashicorp/vagrant/internal/clierrors"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/flags"
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
	client *clientpkg.Client
	// basis to root these operations within
	basis *clientpkg.Basis
	// optional project to run operations within
	project *clientpkg.Project
	// optional target to run operations against
	target *clientpkg.Target

	// clientContext is set to the context information for the current
	// connection. This might not exist in the contextStorage yet if this
	// is from an env var or flags.
	clientContext *clicontext.Config

	// contextStorage is for CLI contexts.
	contextStorage *clicontext.Storage

	//---------------------------------------------------------------
	// Internal fields that should not be accessed directly

	// flagColor is whether the output should use colors.
	flagColor bool

	// flagBasis is the basis to work within.
	flagBasis string

	// flagProject is the project to work within.
	flagProject string

	// flagRemote is whether to execute using a remote runner or use
	// a local runner.
	flagRemote bool

	// flagTarget is the machine to target.
	flagTarget string

	// flagInteractive is whether the output is interactive
	flagInteractive bool

	// flagMachineReadable is whether the terminal ui should only output machine readable data
	flagMachineReadable bool

	// flagConnection contains manual flag-based connection info.
	flagConnection clicontext.Config

	// flagData contains flag info for command
	flagData map[*component.CommandFlag]interface{}

	// args that were present after parsing flags
	args []string

	// options passed in at the global level
	globalOptions []Option

	// used to store cleanup tasks at close
	cleanup cleanup.Cleanup
}

// Close cleans up any resources that the command created. This should be
// defered by any CLI command that embeds baseCommand in the Run command.
func (c *baseCommand) Close() (err error) {
	if c.cleanup == nil {
		return nil
	}

	err = c.cleanup.Close()
	if err != nil {
		c.Log.Error("failure encountered while closing command",
			"error", err,
		)
	}
	return
}

func BaseCommand(ctx context.Context, log hclog.Logger, logOutput io.Writer, opts ...Option) (bc *baseCommand, err error) {
	bc = &baseCommand{
		Ctx:       ctx,
		Log:       log,
		LogOutput: logOutput,
		cleanup:   cleanup.New(),
		flagData:  map[*component.CommandFlag]interface{}{},
	}

	// Define a cleanup to close the UI if it's set
	bc.cleanup.Do(func() error {
		if bc.ui != nil {
			if closer, ok := bc.ui.(io.Closer); ok && closer != nil {
				return closer.Close()
			}
		}
		return err
	})

	// Define a cleanup task to close the client if it's set
	bc.cleanup.Do(func() error {
		if bc.client != nil {
			return bc.client.Close()
		}

		return nil
	})

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

	if c.Args, err = bc.Parse(c.Flags, c.Args, true); err != nil {
		log.Error(clierrors.Humanize(err))
		return nil, err
	}

	// Set UI
	var ui terminal.UI
	if bc.flagMachineReadable {
		// Set machine readable ui if the --machine-readable flag is provided
		ui = terminal.MachineReadableUI(ctx, terminal.TableFormat)
	} else if !bc.flagInteractive {
		// Set non interactive if the --no-interactive flag is provided
		ui = terminal.NonInteractiveUI(ctx)
	} else if !bc.flagColor {
		// Set basic ui (with no color) if the --no-color flag is provided
		ui = terminal.BasicUI(ctx)
	} else {
		// If no ui related flags are set, create a new one
		ui = terminal.ConsoleUI(ctx)
	}
	bc.ui = ui

	outputExperimentalWarning := true
	if val, ok := os.LookupEnv("VAGRANT_SUPPRESS_GO_EXPERIMENTAL_WARNING"); ok {
		if v, err := strconv.ParseBool(val); err == nil && v {
			outputExperimentalWarning = false
		}
	}
	if outputExperimentalWarning {
		ui.Output(`This is an experimental version of Vagrant. Please note that some things may
not work as you expect and this version of Vagrant is not compatible with the 
stable version of Vagrant. For more information about vagrant-go read the docs 
at https://www.vagrantup.com/docs/experimental/vagrant_go. To disable this 
warning set the environment variable 'VAGRANT_SUPPRESS_GO_EXPERIMENTAL_WARNING'.
`, terminal.WithWarningStyle())
	}

	homeConfigPath, err := paths.NamedVagrantConfig(bc.flagBasis)
	if err != nil {
		return nil, err
	}
	bc.Log.Info("vagrant home directory defined",
		"path", homeConfigPath)

	// Setup our directory for context storage
	contextStorage, err := clicontext.NewStorage(
		clicontext.WithDir(homeConfigPath.Join("context")))
	if err != nil {
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
	clientOpts := []clientpkg.Option{
		clientpkg.WithLogger(bc.Log.ResetNamed("vagrant.client")),
		clientpkg.WithClientConnect(connectOpts...),
	}
	if !bc.flagRemote {
		clientOpts = append(clientOpts, clientpkg.WithLocal())
	}

	if bc.ui != nil {
		clientOpts = append(clientOpts, clientpkg.WithUI(bc.ui))
	}

	// And build our client
	bc.client, err = clientpkg.New(ctx, clientOpts...)
	if err != nil {
		return nil, err
	}

	// We always have a basis, so load that
	if bc.basis, err = bc.client.LoadBasis(bc.flagBasis); err != nil {
		return nil, err
	}

	log.Warn("created basis client",
		"basis", bc.basis,
	)

	// A project is optional (though generally needed) and there are
	// two possibilites for how we load the project.
	if bc.flagProject != "" {
		// The first is that we are given a specific project that should be
		// used within the defined basis. So lets load that.
		if bc.project, err = bc.basis.LoadProject(bc.flagProject); err != nil {
			return nil, err
		}
	} else {
		if bc.project, err = bc.basis.DetectProject(); err != nil {
			return nil, err
		}
	}

	// Load in basis vagrantfile if there is one
	if err = bc.basis.LoadVagrantfile(); err != nil {
		return nil, err
	}

	// And if we have a project, load that vagrantfile too
	if bc.project != nil {
		if err = bc.project.LoadVagrantfile(); err != nil {
			return nil, err
		}
	}

	// There's also a chance we are supposed to be focused on
	// a specific target, so load that if so
	if bc.flagTarget != "" {
		if bc.project == nil {
			return nil, fmt.Errorf("cannot load target without valid project")
		}

		if bc.target, err = bc.project.LoadTarget(bc.flagTarget); err != nil {
			return nil, err
		}
	}

	return bc, err
}

// Init initializes the command by parsing flags, parsing the configuration,
// setting up the project, etc. You can control what is done by using the
// options.
//
// Init should be called FIRST within the Run function implementation. Many
// options will affect behavior of other functions that can be called later.
func (c *baseCommand) Init(opts ...Option) (err error) {
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

	// Set UI
	var ui terminal.UI
	if c.flagMachineReadable {
		// Set machine readable ui if the --machine-readable flag is provided
		ui = terminal.MachineReadableUI(c.Ctx, terminal.TableFormat)
	} else if !c.flagInteractive {
		// Set non interactive if the --no-interactive flag is provided
		ui = terminal.NonInteractiveUI(c.Ctx)
	} else if !c.flagColor {
		// Set basic ui (with no color) if the --no-color flag is provided
		ui = terminal.BasicUI(c.Ctx)
	} else {
		// If no ui related flags are set, use the base config ui
		ui = baseCfg.UI
	}
	// If no ui is provided, then build a new UI
	if ui == nil {
		ui = terminal.ConsoleUI(c.Ctx)
	}
	c.ui = ui

	// Parse flags
	c.Log.Warn("generating flags", "flags", baseCfg.Flags)
	if c.args, err = c.Parse(baseCfg.Flags, baseCfg.Args, false); err != nil {
		c.ui.Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return err
	}

	// Parse the configuration (config does not need to exist)
	// TODO: This should be `c.initConfig(true)`,
	//       need to set the basis path first
	c.cfg = &config.Config{}

	// Validate remote vs. local operations.
	if c.flagRemote && c.target == nil {
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

	return nil
}

type Tasker interface {
	UI() terminal.UI
	Command(context.Context, *vagrant_server.Job_CommandOp, client.JobModifier) (*vagrant_server.Job_CommandResult, error)
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
func (c *baseCommand) Do(ctx context.Context, f func(context.Context, *client.Client, client.JobModifier) error) (finalErr error) {
	return f(ctx, c.client, c.Modifier())
}

func (c *baseCommand) Modifier() client.JobModifier {
	return func(j *vagrant_server.Job) {
		if c.target != nil {
			j.Scope = &vagrant_server.Job_Target{
				Target: c.target.Ref(),
			}
			return
		}
		if c.project != nil {
			j.Scope = &vagrant_server.Job_Project{
				Project: c.project.Ref(),
			}
			return
		}
		if c.basis != nil {
			j.Scope = &vagrant_server.Job_Basis{
				Basis: c.basis.Ref(),
			}
			return
		}
	}
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
func (c *baseCommand) flagSet(bit flagSetBit, f func([]*component.CommandFlag) []*component.CommandFlag) component.CommandFlags {
	set := []*component.CommandFlag{
		{
			LongName:     "color",
			Description:  "Can be used to disable colored output",
			DefaultValue: "true",
			Type:         component.FlagBool,
		},
		{
			LongName:     "basis",
			Description:  "Basis to operate within",
			DefaultValue: "default",
			Type:         component.FlagString,
		},
		{
			LongName:     "target",
			Description:  "Target to apply command",
			DefaultValue: "",
			Type:         component.FlagString,
		},
		{
			LongName:     "interactive",
			Description:  "Enable non-interactive output",
			DefaultValue: "true",
			Type:         component.FlagBool,
		},
		{
			LongName:     "machine-readable",
			Description:  "Target to apply command",
			DefaultValue: "false",
			Type:         component.FlagBool,
		},
	}

	if bit&flagSetOperation != 0 {
		set = append(set,
			&component.CommandFlag{
				LongName:     "remote",
				Description:  "Use remote runner to execute",
				DefaultValue: "false",
				Type:         component.FlagBool,
			},
			&component.CommandFlag{
				LongName:    "remote-source",
				Description: "Override how remote runners source data",
				Type:        component.FlagString,
			},
		)
	}

	if bit&flagSetConnection != 0 {
		set = append(set,
			&component.CommandFlag{
				LongName:    "server-addr",
				ShortName:   "",
				Description: "Address for the server",
				Type:        component.FlagString,
			},
			&component.CommandFlag{
				LongName:     "server-tls",
				ShortName:    "",
				Description:  "Connect to server via TLS",
				DefaultValue: "true",
				Type:         component.FlagBool,
			},
			&component.CommandFlag{
				LongName:     "server-tls-skip-verify",
				ShortName:    "",
				Description:  "Skip verification of the TLS certificate advertised by the server",
				DefaultValue: "false",
				Type:         component.FlagBool,
			},
		)
	}

	if f != nil {
		// Configure our values
		set = f(set)
	}

	return set
}

func (c *baseCommand) Parse(
	set []*component.CommandFlag,
	args []string,
	passThrough bool,
) ([]string, error) {
	fset := c.generateCliFlags(set)
	if passThrough {
		flags.SetUnknownMode(flags.PassOnUnknown)(fset)
	}

	c.Log.Warn("parsing arguments with flags", "args", args, "flags", set)
	remainArgs, err := fset.Parse(args)
	if err != nil {
		return nil, err
	}

	for _, f := range set {
		pf, err := fset.Flag(f.LongName)
		if err != nil {
			return nil, err
		}
		// Set the default flag values
		switch f.LongName {
		case "basis":
			c.flagBasis = pf.DefaultValue().(string)
		case "color":
			c.flagColor = pf.DefaultValue().(bool)
		case "target":
			if v := pf.DefaultValue(); v != nil {
				c.flagTarget = pf.DefaultValue().(string)
			}
		case "remote":
			c.flagRemote = pf.DefaultValue().(bool)
		case "interactive":
			c.flagInteractive = pf.DefaultValue().(bool)
		case "machine-readable":
			c.flagMachineReadable = pf.DefaultValue().(bool)
		}
		if !pf.Updated() {
			continue
		}
		// Set the given flag values
		switch f.LongName {
		case "basis":
			c.flagBasis = pf.Value().(string)
		case "color":
			c.flagColor = pf.Value().(bool)
		case "target":
			c.flagTarget = pf.Value().(string)
		case "remote":
			c.flagRemote = pf.Value().(bool)
		case "interactive":
			c.flagInteractive = pf.Value().(bool)
		case "machine-readable":
			c.flagMachineReadable = pf.Value().(bool)
		}
		c.flagData[f] = pf.Value()
	}
	return remainArgs, nil
}

func (c *baseCommand) generateCliFlags(set []*component.CommandFlag) *flags.Set {
	fs := flags.NewSet("flags",
		flags.SetErrorMode(flags.ReturnOnError),
		flags.SetUnknownMode(flags.ErrorOnUnknown),
	)

	for _, f := range set {
		opts := []flags.FlagModifier{}
		if f.Description != "" {
			opts = append(opts, flags.Description(f.Description))
		}
		if f.ShortName != "" {
			opts = append(opts, flags.ShortName(rune(f.ShortName[0])))
		}
		if len(f.Aliases) > 0 {
			opts = append(opts, flags.Alias(f.Aliases...))
		}
		switch f.Type {
		case component.FlagBool:
			b, _ := strconv.ParseBool(f.DefaultValue)
			opts = append(opts, flags.DefaultValue(b))
			fs.DefaultGroup().Bool(f.LongName, opts...)
		case component.FlagString:
			if f.DefaultValue != "" {
				opts = append(opts, flags.DefaultValue(f.DefaultValue))
			}
			fs.DefaultGroup().String(f.LongName, opts...)
		}

	}
	return fs
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
