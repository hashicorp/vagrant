// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package cli

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
)

// Option is used to configure Init on baseCommand.
type Option func(c *baseConfig)

// WithArgs sets the arguments to the command that are used for parsing.
// Remaining arguments can be accessed using your flag set and asking for Args.
// Example: c.Flags().Args().
func WithArgs(args []string) Option {
	return func(c *baseConfig) { c.Args = args }
}

// WithFlags sets the flags that are supported by this command. This MUST
// be set otherwise a panic will happen. This is usually set by just calling
// the Flags function on your command implementation.
func WithFlags(f []*component.CommandFlag) Option {
	return func(c *baseConfig) { c.Flags = f }
}

// TODO(spox): needs to be updated to using arg value for machine name
// WithSingleMachine configures the CLI to expect a configuration with
// one or more machines defined but a single machine targeted with `-app`.
// If only a single machine exists, it is implicitly the target.
// Zero machine is an error.
func WithSingleTarget() Option {
	return func(c *baseConfig) {
		c.TargetRequired = true
		c.Config = false
		c.Client = true
	}
}

// WithNoConfig configures the CLI to not expect any project configuration.
// This will not read any configuration files.
func WithNoConfig() Option {
	return func(c *baseConfig) {
		c.Config = false
	}
}

// WithConfig configures the CLI to find and load any project configuration.
// If optional is true, no error will be shown if a config can't be found.
func WithConfig(optional bool) Option {
	return func(c *baseConfig) {
		c.Config = true
		c.ConfigOptional = optional
	}
}

// WithClient configures the CLI to initialize a client.
func WithClient(v bool) Option {
	return func(c *baseConfig) {
		c.Client = v
	}
}

// WithUI configures the CLI to use a specific UI implementation
func WithUI(ui terminal.UI) Option {
	return func(c *baseConfig) {
		c.UI = ui
	}
}

type baseConfig struct {
	Args           []string
	Flags          component.CommandFlags
	Config         bool
	ConfigOptional bool
	Client         bool
	TargetRequired bool
	UI             terminal.UI
}
