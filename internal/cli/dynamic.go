package cli

import (
	"context"
	"errors"
	"reflect"
	"strconv"

	"github.com/DavidGamba/go-getoptions"
	"github.com/DavidGamba/go-getoptions/option"

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
	flags    []*option.Option
	flagData map[string]interface{}
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
		for k, v := range c.flagData {
			f := &vagrant_plugin_sdk.Command_Arguments_Flag{Name: k}
			switch reflect.Indirect(reflect.ValueOf(v)).Kind() {
			case reflect.String:
				f.Value = &vagrant_plugin_sdk.Command_Arguments_Flag_String_{
					String_: *v.(*string),
				}
				f.Type = vagrant_plugin_sdk.Command_Arguments_Flag_STRING
			case reflect.Bool:
				f.Value = &vagrant_plugin_sdk.Command_Arguments_Flag_Bool{
					Bool: *v.(*bool),
				}
				f.Type = vagrant_plugin_sdk.Command_Arguments_Flag_BOOL
			}
			taskArgs.Flags = append(taskArgs.Flags, f)
		}

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
			cl.UI().Output("Error: "+r.RunError.Message+"\n", terminal.WithErrorStyle())
			err = errors.New("execution failed")
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
	return c.help
}

func (c *DynamicCommand) Flags() *getoptions.GetOpt {
	return c.flagSet(flagSetOperation, func(opts *getoptions.GetOpt) {
		for _, f := range c.flags {
			switch f.OptType {
			case option.BoolType:
				b, _ := strconv.ParseBool(f.DefaultStr)
				c.flagData[f.Name] = opts.Bool(
					f.Name,
					b,
					opts.Description(f.Description),
				)
			case option.StringType:
				c.flagData[f.Name] = opts.String(
					f.Name,
					f.DefaultStr,
					opts.Description(f.Description),
				)
			}
		}
	})
}
