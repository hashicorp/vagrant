package serverclient

import (
	"context"
	"errors"

	"github.com/golang/protobuf/ptypes/empty"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"

	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/pluginclient"
	"github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant"
)

type RubyVagrant interface {
	GetPlugins() ([]*ruby_vagrant.Plugin, error)
	ParseVagrantfile(string) (*ruby_vagrant.Vagrantfile, error)
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
	log = log.Named("vagrant-ruby-runtime")
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
	plugins, err := r.client.GetPlugins(context.Background(), &empty.Empty{})
	if err != nil {
		return nil, err
	}
	return plugins.Plugins, nil
}

// TODO: This should return an hcl Vagrantfile representation
func (r *RubyVagrantClient) ParseVagrantfile(path string) (*ruby_vagrant.Vagrantfile, error) {
	vf, err := r.client.ParseVagrantfile(
		context.Background(),
		&ruby_vagrant.ParseVagrantfileRequest{Path: path},
	)
	if err != nil {
		return nil, err
	}
	return vf.Vagrantfile, nil
}
