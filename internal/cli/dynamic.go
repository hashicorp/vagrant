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

	err := c.Do(c.Ctx, func(ctx context.Context, tasker Tasker) error {
		tasker.UI().Output("Running "+c.name+"... ", terminal.WithHeaderStyle())
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
		result, err := tasker.Task(ctx, &vagrant_server.Job_RunOp{
			Task: &vagrant_server.Task{
				Scope: &vagrant_server.Task_Machine{
					Machine: tasker.(*client.Machine).Ref(),
				},
				Task: c.name,
				Component: &vagrant_server.Component{
					Type: vagrant_server.Component_COMMAND,
					Name: c.name,
				},
				CliArgs: taskArgs,
			},
		})

		if err != nil {
			tasker.UI().Output("Running of task "+c.name+" failed unexpectedly\n", terminal.WithErrorStyle())
			tasker.UI().Output("Error: "+err.Error(), terminal.WithErrorStyle())
		} else if !result.RunResult {
			tasker.UI().Output("Error: "+result.RunError.Message+"\n", terminal.WithErrorStyle())
			err = errors.New("execution failed")
		}

		c.Log.Debug("result from operation", "task", c.name, "result", result)

		return err
	})

	if err != nil {
		return 1
	}

	return 0
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
