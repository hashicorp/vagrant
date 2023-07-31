// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

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

	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/protomappers"
	"github.com/hashicorp/vagrant-plugin-sdk/localizer"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
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
		// Write help to stdout to match Ruby vagrant behavior
		HelpWriter: os.Stdout,
		// Need to set Version on the CLI to enable `-v` and `--version` handling
		Version: vsn.FullVersionNumber(true),
	}

	// Run the CLI
	exitCode, err := cli.Run()
	if err != nil {
		log.Error("cli run failed", "error", err)
		panic(err)
	}

	// Close the base here manually so we can detect if an
	// error was encountered and modify the exit code if so
	err = base.Close()
	if err != nil {
		exitCode = -1
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

	result, err := baseCommand.client.Commands(ctx, nil, baseCommand.Modifier())
	if err != nil {
		return nil, nil, err
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
		registerCommand(result.Commands[i], commands, baseCommand, nil)
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

func registerCommand(
	c *vagrant_plugin_sdk.Command_CommandInfo,
	cmds map[string]cli.CommandFactory,
	base *baseCommand,
	parent *DynamicCommand,
) {
	flgs, err := protomappers.Flags(c.Flags)
	if err != nil {
		panic(err)
	}

	d := &DynamicCommand{
		baseCommand: base,
		name:        c.Name,
		synopsis:    c.Synopsis,
		help:        c.Help,
		flags:       flgs,
		primary:     c.Primary,
	}
	if parent != nil {
		d.parent = parent
	}

	cmds[d.fullName()] = func() (cli.Command, error) {
		return d, nil
	}

	if c.Subcommands != nil && len(c.Subcommands) > 0 {
		for _, s := range c.Subcommands {
			registerCommand(s, cmds, base, d)
		}
	}
}

// logger returns the logger to use for the CLI. Output, level, etc. are
// determined based on environment variables if set.
func logger(args []string) ([]string, hclog.Logger, io.Writer, error) {
	app := args[0]
	verbose := false

	// Determine our log level if we have any. First override we check is env var
	level := hclog.NoLevel
	if v := os.Getenv(EnvLogLevel); v != "" {
		level = hclog.LevelFromString(v)
		if level == hclog.NoLevel {
			return nil, nil, nil, fmt.Errorf("%s value %q is not a valid log level", EnvLogLevel, v)
		}
	}

	// Set default log level
	_ = os.Setenv("VAGRANT_LOG", "fatal")

	// Process arguments looking for `-v` flags to control the log level.
	// This overrides whatever the env var set.
	var outArgs []string
	for _, arg := range args {
		if len(arg) != 0 && arg[0] != '-' {
			outArgs = append(outArgs, arg)
			continue
		}

		switch arg {
		case "-V":
			if level == hclog.NoLevel || level > hclog.Info {
				level = hclog.Info
				_ = os.Setenv("VAGRANT_LOG", "info")
			}
		case "-VV":
			if level == hclog.NoLevel || level > hclog.Debug {
				level = hclog.Debug
				_ = os.Setenv("VAGRANT_LOG", "debug")
			}
		case "-VVV":
			if level == hclog.NoLevel || level > hclog.Trace {
				level = hclog.Trace
				_ = os.Setenv("VAGRANT_LOG", "trace")
			}
		case "-VVVV":
			if level == hclog.NoLevel || level > hclog.Trace {
				level = hclog.Trace
				_ = os.Setenv("VAGRANT_LOG", "trace")
			}
			verbose = true
		case "--debug":
			if level == hclog.NoLevel || level > hclog.Debug {
				level = hclog.Debug
				_ = os.Setenv("VAGRANT_LOG", "debug")
			}
		case "--timestamp":
			t := terminal.NonInteractiveUI(context.Background())
			t.Output(
				localizer.LocalizeMsg("deprecated_flag", map[string]string{"Flag": "--timestamp"}),
			)
		case "--debug-timestamp":
			if level == hclog.NoLevel || level > hclog.Debug {
				level = hclog.Debug
				_ = os.Setenv("VAGRANT_LOG", "debug")
			}
			t := terminal.NonInteractiveUI(context.Background())
			t.Output(
				localizer.LocalizeMsg("deprecated_flag", map[string]string{"Flag": "--debug-timestamp"}),
			)
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

	// Since some log line can get extremely verbose depending on what
	// fields are included, this will suppress overly long trace lines
	// unless we are in verbose mode.
	exclude := func(level hclog.Level, msg string, args ...interface{}) bool {
		if level != hclog.Trace || verbose {
			return false
		}

		for _, a := range args {
			if len(fmt.Sprintf("%v", a)) > 150 {
				return true
			}
		}
		return false
	}

	logger := hclog.New(&hclog.LoggerOptions{
		Name:    app,
		Level:   level,
		Color:   color,
		Output:  output,
		Exclude: exclude,
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

		// First add hand-picked common commands
		helpCommandsSection(d, "Common commands", commonCommands, commands)

		// Make our list of other commands by
		//   - skipping common commands we just printed
		//   - skipping hand-picked hidden commands
		//   - skipping commands that set CommandOptions.Primary to false
		ignoreMap := map[string]struct{}{}
		for k := range hiddenCommands {
			ignoreMap[k] = struct{}{}
		}
		for _, k := range commonCommands {
			ignoreMap[k] = struct{}{}
		}

		for k, cmdFn := range commands {
			cmd, err := cmdFn()
			if err != nil {
				panic(fmt.Sprintf("failed to load %q command: %s", k, err))
			}
			if pc, ok := cmd.(Primaryable); ok && pc.Primary() == false {
				ignoreMap[k] = struct{}{}
			}
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

type Primaryable interface {
	Primary() bool
}

var helpText = map[string][2]string{}
