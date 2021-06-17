package cli

//go:generate go-bindata -nomemcopy -nometadata -pkg datagen -o datagen/datagen.go -prefix data/ data/...

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"sort"
	"text/tabwriter"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"github.com/mitchellh/cli"
	"github.com/mitchellh/go-glint"

	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/core"
	"github.com/hashicorp/vagrant/internal/pkg/signalcontext"
	"github.com/hashicorp/vagrant/internal/version"
)

const (
	// EnvLogLevel is the env var to set with the log level.
	EnvLogLevel = "VAGRANT_LOG_LEVEL"

	// EnvPlain is the env var that can be set to force plain output mode.
	EnvPlain = "VAGRANT_PLAIN"
)

var (
	// cliName is the name of this CLI.
	cliName = "vagrant"

	// commonCommands are the commands that are deemed "common" and shown first
	// in the CLI help output.
	commonCommands = []string{
		"up",
		"destroy",
		"halt",
		"status",
		"reload",
	}

	// hiddenCommands are not shown in CLI help output.
	hiddenCommands = map[string]struct{}{
		"plugin-run": {},
	}

	ExposeDocs bool
)

// Main runs the CLI with the given arguments and returns the exit code.
// The arguments SHOULD include argv[0] as the program name.
func Main(args []string) int {
	// Clean up all our plugins so we don't leave any dangling processes.
	// Note that this is a "just in case" catch. We should be properly cleaning
	// up plugin processes by calling Close on all the resources we use.
	defer plugin.CleanupClients()

	// Initialize our logger based on env vars
	args, log, logOutput, err := logger(args)
	if err != nil {
		panic(err)
	}

	// Log our versions
	vsn := version.GetVersion()
	log.Info("vagrant version",
		"full_string", vsn.FullVersionNumber(true),
		"version", vsn.Version,
		"prerelease", vsn.VersionPrerelease,
		"metadata", vsn.VersionMetadata,
		"revision", vsn.Revision,
	)

	// Build our cancellation context
	ctx, closer := signalcontext.WithInterrupt(context.Background(), log)
	defer closer()

	// Get our base command
	base, commands, err := Commands(ctx, args, log, logOutput)
	if err != nil {
		panic(err)
	}
	defer base.Close()

	// Build the CLI
	cli := &cli.CLI{
		Name:                       args[0],
		Args:                       args[1:],
		Commands:                   commands,
		Autocomplete:               true,
		AutocompleteNoDefaultFlags: true,
		HelpFunc:                   GroupedHelpFunc(cli.BasicHelpFunc(cliName)),
	}

	// Run the CLI
	exitCode, err := cli.Run()
	if err != nil {
		panic(err)
	}

	return exitCode
}

// commands returns the map of commands that can be used to initialize a CLI.
func Commands(
	ctx context.Context,
	args []string,
	log hclog.Logger,
	logOutput io.Writer,
	opts ...Option,
) (*baseCommand, map[string]cli.CommandFactory, error) {
	commands := make(map[string]cli.CommandFactory)

	bc := &baseCommand{
		Ctx:       ctx,
		Log:       log,
		LogOutput: logOutput,
	}
	// fetch plugin builtin commands
	commands["plugin-run"] = func() (cli.Command, error) {
		return &PluginCommand{
			baseCommand: bc,
		}, nil
	}

	// If running a builtin don't do all the setup
	if len(args) > 1 && args[1] == "plugin-run" {
		return bc, commands, nil
	}

	baseCommand, err := BaseCommand(ctx, log, logOutput,
		WithArgs(args),
	)
	if err != nil {
		return nil, nil, err
	}

	basis := baseCommand.basis

	// // Using a custom UI here to prevent weird output behavior
	// // TODO(spox): make this better (like respecting noninteractive, etc)
	ui := terminal.ConsoleUI(ctx)
	s := ui.Status()
	s.Update("Loading Vagrant...")

	result, err := basis.Commands(ctx, nil)
	if err != nil {
		s.Step(terminal.StatusError, "Failed to load Vagrant!")
		return nil, nil, err
	}

	s.Step(terminal.StatusOK, "Vagrant loaded!")
	s.Close()

	if closer, ok := ui.(io.Closer); ok {
		closer.Close()
	}

	// Set plain mode if set
	if os.Getenv(EnvPlain) != "" {
		baseCommand.globalOptions = append(baseCommand.globalOptions,
			WithUI(terminal.NonInteractiveUI(ctx)))
	}

	// aliases is a list of command aliases we have. The key is the CLI
	// command (the alias) and the value is the existing target command.
	aliases := map[string]string{}

	// fetch remaining builtin commands
	commands["version"] = func() (cli.Command, error) {
		return &VersionCommand{
			baseCommand: baseCommand,
			VersionInfo: version.GetVersion(),
		}, nil
	}
	// add dynamic commands
	// TODO(spox): reverse the setup here so we load
	//             dynamic commands first and then define
	//             any builtin commands on top so the builtin
	//             commands have proper precedence.
	for i := 0; i < len(result.Commands); i++ {
		n := result.Commands[i]

		flgs, _ := core.ProtoToFlagsMapper(n.Flags)
		if _, ok := commands[n.Name]; !ok {
			commands[n.Name] = func() (cli.Command, error) {
				return &DynamicCommand{
					baseCommand: baseCommand,
					name:        n.Name,
					synopsis:    n.Synopsis,
					help:        n.Help,
					flags:       flgs,
					flagData:    make(map[string]interface{}),
				}, nil
			}
		}
	}

	// fetch all known plugin commands
	commands["plugin"] = func() (cli.Command, error) {
		return &PluginCommand{
			baseCommand: baseCommand,
		}, nil
	}
	commands["version"] = func() (cli.Command, error) {
		return &VersionCommand{
			baseCommand: baseCommand,
			VersionInfo: version.GetVersion(),
		}, nil
	}

	// register our aliases
	for from, to := range aliases {
		commands[from] = commands[to]
	}

	return baseCommand, commands, nil
}

// logger returns the logger to use for the CLI. Output, level, etc. are
// determined based on environment variables if set.
func logger(args []string) ([]string, hclog.Logger, io.Writer, error) {
	app := args[0]

	// Determine our log level if we have any. First override we check is env var
	level := hclog.NoLevel
	if v := os.Getenv(EnvLogLevel); v != "" {
		level = hclog.LevelFromString(v)
		if level == hclog.NoLevel {
			return nil, nil, nil, fmt.Errorf("%s value %q is not a valid log level", EnvLogLevel, v)
		}
	}

	// Process arguments looking for `-v` flags to control the log level.
	// This overrides whatever the env var set.
	var outArgs []string
	for _, arg := range args {
		if len(arg) != 0 && arg[0] != '-' {
			outArgs = append(outArgs, arg)
			continue
		}

		switch arg {
		case "-v":
			if level == hclog.NoLevel || level > hclog.Info {
				level = hclog.Info
			}
		case "-vv":
			if level == hclog.NoLevel || level > hclog.Debug {
				level = hclog.Debug
			}
		case "-vvv":
			if level == hclog.NoLevel || level > hclog.Trace {
				level = hclog.Trace
			}
		default:
			outArgs = append(outArgs, arg)
		}
	}

	// Default output is nowhere unless we enable logging.
	var output io.Writer = ioutil.Discard
	color := hclog.ColorOff
	if level != hclog.NoLevel {
		output = os.Stderr
		color = hclog.AutoColor
	}

	logger := hclog.New(&hclog.LoggerOptions{
		Name:   app,
		Level:  level,
		Color:  color,
		Output: output,
	})

	return outArgs, logger, output, nil
}

func GroupedHelpFunc(f cli.HelpFunc) cli.HelpFunc {
	return func(commands map[string]cli.CommandFactory) string {
		var buf bytes.Buffer
		d := glint.New()
		d.SetRenderer(&glint.TerminalRenderer{
			Output: &buf,

			// We set rows/cols here manually. The important bit is the cols
			// needs to be wide enough so glint doesn't clamp any text and
			// lets the terminal just autowrap it. Rows doesn't make a big
			// difference.
			Rows: 10,
			Cols: 180,
		})

		// Header
		d.Append(glint.Style(
			glint.Text("Welcome to Vagrant"),
			glint.Bold(),
		))
		d.Append(glint.Layout(
			glint.Style(
				glint.Text("Docs:"),
				glint.Color("lightBlue"),
			),
			glint.Text(" "),
			glint.Text("https://vagrantup.com"),
		).Row())
		d.Append(glint.Layout(
			glint.Style(
				glint.Text("Version:"),
				glint.Color("green"),
			),
			glint.Text(" "),
			glint.Text(version.GetVersion().VersionNumber()),
		).Row())
		d.Append(glint.Text(""))

		// Usage
		d.Append(glint.Layout(
			glint.Style(
				glint.Text("Usage:"),
				glint.Color("lightMagenta"),
			),
			glint.Text(" "),
			glint.Text(cliName),
			glint.Text(" "),
			glint.Text("[-version] [-help] [-autocomplete-(un)install] <command> [args]"),
		).Row())
		d.Append(glint.Text(""))

		// Add common commands
		helpCommandsSection(d, "Common commands", commonCommands, commands)

		// Make our other commands
		ignoreMap := map[string]struct{}{}
		for k := range hiddenCommands {
			ignoreMap[k] = struct{}{}
		}
		for _, k := range commonCommands {
			ignoreMap[k] = struct{}{}
		}

		var otherCommands []string
		for k := range commands {
			if _, ok := ignoreMap[k]; ok {
				continue
			}

			otherCommands = append(otherCommands, k)
		}
		sort.Strings(otherCommands)

		// Add other commands
		helpCommandsSection(d, "Other commands", otherCommands, commands)

		d.RenderFrame()
		return buf.String()
	}
}

func helpCommandsSection(
	d *glint.Document,
	header string,
	commands []string,
	factories map[string]cli.CommandFactory,
) {
	// Header
	d.Append(glint.Style(
		glint.Text(header),
		glint.Bold(),
	))

	// Build our commands
	var b bytes.Buffer
	tw := tabwriter.NewWriter(&b, 0, 2, 6, ' ', 0)
	for _, k := range commands {
		fn, ok := factories[k]
		if !ok {
			continue
		}

		cmd, err := fn()
		if err != nil {
			panic(fmt.Sprintf("failed to load %q command: %s", k, err))
		}

		fmt.Fprintf(tw, "%s\t%s\n", k, cmd.Synopsis())
	}
	tw.Flush()

	d.Append(glint.Layout(
		glint.Text(b.String()),
	).PaddingLeft(2))
}

var helpText = map[string][2]string{}
