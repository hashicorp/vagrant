// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package cli

import (
	"fmt"
	"strings"
	"time"

	"github.com/skratchdot/open-golang/open"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/clierrors"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

type UICommand struct {
	*baseCommand

	flagAuthenticate bool
}

func (c *UICommand) Run(args []string) int {
	// Initialize. If we fail, we just exit since Init handles the UI.
	if err := c.Init(
		WithArgs(args),
		WithFlags(c.Flags()),
		WithNoConfig(),
	); err != nil {
		return 1
	}

	// TODO(spox): comment this out until local configuration is updated
	// if c.client.Local() {
	// 	c.client.UI().Output("Vagrant must be configured in server mode to access the UI", terminal.WithWarningStyle())
	// }

	// Get our API client
	client := c.basis.Client()

	var inviteToken string
	if c.flagAuthenticate {
		c.ui.Output("Creating invite token", terminal.WithStyle(terminal.HeaderStyle))
		c.ui.Output("This invite token will be exchanged for an authentication \ntoken that your browser stores.")

		resp, err := client.GenerateInviteToken(c.Ctx, &vagrant_server.InviteTokenRequest{
			Duration: (2 * time.Minute).String(),
		})
		if err != nil {
			c.basis.UI().Output(clierrors.Humanize(err), terminal.WithErrorStyle())
			return 1
		}

		inviteToken = resp.Token
	}

	// Get our default context (used context)
	name, err := c.contextStorage.Default()
	if err != nil {
		c.basis.UI().Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return 1
	}

	ctxConfig, err := c.contextStorage.Load(name)
	if err != nil {
		c.basis.UI().Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return 1
	}

	// todo(mitchellh: current default port is hardcoded, cannot configure http address)
	addr := strings.Split(ctxConfig.Server.Address, ":")[0]
	// Default Docker platform HTTP port, for now
	port := 9702
	if err != nil {
		c.basis.UI().Output(clierrors.Humanize(err), terminal.WithErrorStyle())
		return 1
	}

	c.ui.Output("Opening browser", terminal.WithStyle(terminal.HeaderStyle))

	uiAddr := fmt.Sprintf("https://%s:%d", addr, port)
	if c.flagAuthenticate {
		uiAddr = fmt.Sprintf("%s/auth/invite?token=%s&cli=true", uiAddr, inviteToken)
	}

	open.Run(uiAddr)

	return 0
}

func (c *UICommand) Flags() component.CommandFlags {
	return c.flagSet(0, func(set []*component.CommandFlag) []*component.CommandFlag {
		return append(set,
			&component.CommandFlag{
				LongName:     "authenticate",
				Description:  "Creates a new invite token and passes it to the UI for authorization",
				DefaultValue: "false",
			},
		)
	})
}

func (c *UICommand) Primary() bool {
	return true
}

// func (c *UICommand) AutocompleteArgs() complete.Predictor {
// 	return complete.PredictNothing
// }

// func (c *UICommand) AutocompleteFlags() complete.Flags {
// 	return c.Flags().Completions()
// }

func (c *UICommand) Synopsis() string {
	return "Open the web UI"
}

func (c *UICommand) Help() string {
	return formatHelp(`
Usage: vagrant ui [options]

  Opens the new UI. When provided a flag, will automatically open the
  token invite page with an invite token for authentication.

` + c.Flags().Display())
}
