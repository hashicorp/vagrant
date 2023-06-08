package cli

import (
	"context"
	"fmt"

	"google.golang.org/genproto/googleapis/rpc/errdetails"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/client"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type DynamicCommand struct {
	*baseCommand

	name     string
	synopsis string
	help     string
	parent   *DynamicCommand
	flags    []*component.CommandFlag
	primary  bool
}

func (c *DynamicCommand) Run(args []string) int {
	if err := c.Init(
		WithArgs(args),
		WithFlags(c.Flags()),
	); err != nil {
		return 1
	}

	var r *vagrant_server.Job_CommandResult
	err := c.Do(c.Ctx, func(ctx context.Context, cl *client.Client, modifier client.JobModifier) (err error) {
		cmdArgs := &vagrant_plugin_sdk.Command_Arguments{
			Args:  c.args,
			Flags: []*vagrant_plugin_sdk.Command_Arguments_Flag{},
		}
		for f, v := range c.flagData {
			cmdFlag := &vagrant_plugin_sdk.Command_Arguments_Flag{Name: f.LongName}
			switch f.Type {
			case component.FlagBool:
				cmdFlag.Type = vagrant_plugin_sdk.Command_Arguments_Flag_BOOL
				cmdFlag.Value = &vagrant_plugin_sdk.Command_Arguments_Flag_Bool{
					Bool: v.(bool),
				}
			case component.FlagString:
				cmdFlag.Type = vagrant_plugin_sdk.Command_Arguments_Flag_STRING
				cmdFlag.Value = &vagrant_plugin_sdk.Command_Arguments_Flag_String_{
					String_: v.(string),
				}
			}
			cmdArgs.Flags = append(cmdArgs.Flags, cmdFlag)
		}

		c.Log.Debug("collected argument flags",
			"flags", cmdArgs.Flags,
			"args", args,
			"remaining", c.args,
		)

		cOp := &vagrant_server.Job_CommandOp{
			Command: c.name,
			Component: &vagrant_server.Component{
				Type: vagrant_server.Component_COMMAND,
				Name: c.name,
			},
			CliArgs: cmdArgs,
		}

		r, err = cl.Command(ctx, cOp, modifier)

		// If nothing failed but we didn't get a Result back, something may
		// have gone wrong on the far side so we need to interpret the error.
		if err == nil && !r.RunResult {
			runErrorStatus := status.FromProto(r.RunError)
			details := runErrorStatus.Details()
			userError := false
			for _, msg := range details {
				switch m := msg.(type) {
				case *errdetails.LocalizedMessage:
					// Errors from Ruby with LocalizedMessages are user-facing,
					// so can be output directly.
					userError = true
					cl.UI().Output(m.Message, terminal.WithErrorStyle())
					// All user-facing errors from Ruby use a 1 exit code. See
					// Vagrant::Errors::VagrantError.
					r.ExitCode = 1
				}
			}
			// If there wasn't a user-facing error, just assign the returned
			// error (if any) from the response and assign that back out so it
			// can be displayed as an unexpected error.
			if !userError {
				err = runErrorStatus.Err()
			}
		}

		if err != nil {
			cl.UI().Output("Running of task "+c.name+" failed unexpectedly\n", terminal.WithErrorStyle())
			cl.UI().Output("Error: "+err.Error(), terminal.WithErrorStyle())
		}

		c.Log.Debug("result from operation", "task", c.name, "result", r)

		return err
	})

	if err != nil {
		c.Log.Error("Got error from task, so exiting 255", "error", err)
		return int(-1)
	}

	c.Log.Info("Task did not error, so exiting with provided code", "code", r.ExitCode)
	return int(r.ExitCode)
}

func (c *DynamicCommand) Synopsis() string {
	return c.synopsis
}

func (c *DynamicCommand) Help() string {
	fset := c.generateCliFlags(c.Flags())
	return formatHelp(fmt.Sprintf("%s\n%s\n", c.help, fset.Display()))
}

func (c *DynamicCommand) Flags() component.CommandFlags {
	return c.flagSet(flagSetOperation, func(opts []*component.CommandFlag) []*component.CommandFlag {
		return append(c.flags, opts...)
	})
}

func (c *DynamicCommand) Primary() bool {
	return c.primary
}

func (c *DynamicCommand) fullName() string {
	var v string
	if c.parent != nil {
		v = c.parent.fullName() + " "
	}
	return v + c.name
}
