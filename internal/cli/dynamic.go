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
}

func (c *DynamicCommand) Run(args []string) int {
	if err := c.Init(
		WithArgs(args),
		WithFlags(c.Flags()),
	); err != nil {
		return 1
	}

	var r *vagrant_server.Job_RunResult
	err := c.Do(c.Ctx, func(ctx context.Context, cl *client.Client, modifier client.JobModifier) (err error) {
		cl.UI().Output("Running "+c.name+"... ", terminal.WithHeaderStyle())
		taskArgs := &vagrant_plugin_sdk.Command_Arguments{
			Args:  args,
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
			taskArgs.Flags = append(taskArgs.Flags, cmdFlag)
		}

		c.Log.Info("collected argument flags", "flags", taskArgs.Flags, "args", args)

		t := &vagrant_server.Task{
			Task: c.name,
			Component: &vagrant_server.Component{
				Type: vagrant_server.Component_COMMAND,
				Name: c.name,
			},
			CliArgs:     taskArgs,
			CommandName: c.name,
		}

		if c.basis != nil {
			t.Scope = &vagrant_server.Task_Basis{
				Basis: c.basis.Ref(),
			}
		}

		if c.project != nil {
			t.Scope = &vagrant_server.Task_Project{
				Project: c.project.Ref(),
			}
		}

		if c.target != nil {
			t.Scope = &vagrant_server.Task_Target{
				Target: c.target.Ref(),
			}
		}

		r, err = cl.Task(ctx,
			&vagrant_server.Job_RunOp{Task: t},
			modifier,
		)

		if err != nil {
			cl.UI().Output("Running of task "+c.name+" failed unexpectedly\n", terminal.WithErrorStyle())
			cl.UI().Output("Error: "+err.Error(), terminal.WithErrorStyle())
		} else if !r.RunResult {
			runErrorStatus := status.FromProto(r.RunError)
			details := runErrorStatus.Details()
			for _, msg := range details {
				switch m := msg.(type) {
				case *errdetails.LocalizedMessage:
					cl.UI().Output("Error: "+m.Message+"\n", terminal.WithErrorStyle())
				}
			}
			runErr := status.FromProto(r.RunError)
			err = fmt.Errorf("execution failed, %w", runErr.Err())
		}

		c.Log.Debug("result from operation", "task", c.name, "result", r)

		return err
	})

	if err != nil {
		return int(-1)
	}

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

func (c *DynamicCommand) fullName() string {
	var v string
	if c.parent != nil {
		v = c.parent.fullName() + " "
	}
	return v + c.name
}
