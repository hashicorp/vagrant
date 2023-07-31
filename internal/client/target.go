// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package client

import (
	"context"

	"github.com/hashicorp/go-hclog"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type Target struct {
	client  *Client
	ctx     context.Context
	logger  hclog.Logger
	project *Project
	target  *vagrant_server.Target
	ui      terminal.UI
	vagrant *serverclient.VagrantClient
}

func (m *Target) UI() terminal.UI {
	return m.ui
}

func (m *Target) Ref() *vagrant_plugin_sdk.Ref_Target {
	return &vagrant_plugin_sdk.Ref_Target{
		ResourceId: m.target.ResourceId,
		Name:       m.target.Name,
		Project:    m.project.Ref(),
	}
}
