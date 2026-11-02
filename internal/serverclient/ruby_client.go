// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package serverclient

import (
	"context"
	"errors"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"
	"google.golang.org/protobuf/types/known/emptypb"

	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/pluginclient"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant"
)

type RubyVagrant interface {
	GetPlugins() ([]*ruby_vagrant.Plugin, error)
	ParseVagrantfile(string) (*vagrant_plugin_sdk.Vagrantfile_Vagrantfile, error)
}

// This is the implementation of plugin.GRPCPlugin so we can serve/consume this.
type RubyVagrantPlugin struct {
	plugin.NetRPCUnsupportedPlugin

	Impl RubyVagrant
}

type RubyVagrantClient struct {
	broker *plugin.GRPCBroker
	client ruby_vagrant.RubyVagrantClient
	ctx    context.Context
}

func RubyVagrantPluginConfig(log hclog.Logger) *plugin.ClientConfig {
	log = log.ResetNamed("vagrant.legacy")
	config := pluginclient.ClientConfig(log)
	config.Logger = log
	config.VersionedPlugins[1]["vagrantrubyruntime"] = &RubyVagrantPlugin{}
	return config
}

// No Go server implementation. Server is provided by the Vagrant Ruby runtime
func (p *RubyVagrantPlugin) GRPCServer(broker *plugin.GRPCBroker, s *grpc.Server) error {
	return errors.New("vagrant ruby runtime server not implemented")
}

func (p *RubyVagrantPlugin) GRPCClient(ctx context.Context, broker *plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	return RubyVagrantClient{
		broker: broker,
		client: ruby_vagrant.NewRubyVagrantClient(c),
		ctx:    ctx,
	}, nil
}

func (r *RubyVagrantClient) GRPCBroker() *plugin.GRPCBroker {
	return r.broker
}

func (r *RubyVagrantClient) GetPlugins() ([]*ruby_vagrant.Plugin, error) {
	plugins, err := r.client.GetPlugins(context.Background(), &ruby_vagrant.GetPluginsRequest{})
	if err != nil {
		return nil, err
	}
	return plugins.Plugins, nil
}

func (r *RubyVagrantClient) ParseVagrantfile(path string) (*vagrant_plugin_sdk.Args_Hash, error) {
	vf, err := r.client.ParseVagrantfile(
		context.Background(),
		&ruby_vagrant.ParseVagrantfileRequest{Path: path},
	)
	if err != nil {
		return nil, err
	}

	return vf.Data, nil
}

func (r *RubyVagrantClient) ParseVagrantfileProc(ref *vagrant_plugin_sdk.Args_ProcRef) (*vagrant_plugin_sdk.Args_Hash, error) {
	vf, err := r.client.ParseVagrantfileProc(
		context.Background(),
		&ruby_vagrant.ParseVagrantfileProcRequest{
			Proc: ref,
		},
	)
	if err != nil {
		return nil, err
	}

	return vf.Data, nil
}

func (r *RubyVagrantClient) ParseVagrantfileSubvm(subvm *vagrant_plugin_sdk.Config_RawRubyValue) (*vagrant_plugin_sdk.Args_Hash, error) {
	resp, err := r.client.ParseVagrantfileSubvm(
		context.Background(),
		&ruby_vagrant.ParseVagrantfileSubvmRequest{
			Subvm: subvm,
		},
	)

	if err != nil {
		return nil, err
	}

	return resp.Data, nil
}

func (r *RubyVagrantClient) ParseVagrantfileProvider(provider string, subvm *vagrant_plugin_sdk.Config_RawRubyValue) (*vagrant_plugin_sdk.Args_Hash, error) {
	resp, err := r.client.ParseVagrantfileProvider(
		context.Background(),
		&ruby_vagrant.ParseVagrantfileProviderRequest{
			Provider: provider,
			Subvm:    subvm,
		},
	)

	if err != nil {
		return nil, err
	}

	return resp.Data, nil
}

func (r *RubyVagrantClient) Stop() error {
	_, err := r.client.Stop(context.Background(), &emptypb.Empty{})
	if err != nil {
		return err
	}

	return nil
}
