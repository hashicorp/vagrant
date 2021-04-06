package server

import (
	"context"
	"errors"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"

	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/pluginclient"
	"github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant"
	"github.com/hashicorp/vagrant/internal/serverclient"
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

func RubyVagrantPluginConfig(log hclog.Logger) *plugin.ClientConfig {
	log = log.Named("vagrant-ruby")
	config := pluginclient.ClientConfig(log)
	config.Logger = log
	config.VersionedPlugins[1]["rubyvagrantserver"] = &RubyVagrantPlugin{}
	return config
}

// No go implementation
func (p *RubyVagrantPlugin) GRPCServer(broker *plugin.GRPCBroker, s *grpc.Server) error {
	return errors.New("vagrant ruby runtime server not implemented")
}

func (p *RubyVagrantPlugin) GRPCClient(ctx context.Context, broker *plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	return serverclient.WrapRubyVagrantClient(c), nil
}
