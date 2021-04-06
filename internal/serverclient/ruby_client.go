package serverclient

import (
	"context"
	"fmt"

	"github.com/golang/protobuf/ptypes/empty"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"

	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/pluginclient"

	"github.com/hashicorp/vagrant/internal/protocolversion"
	"github.com/hashicorp/vagrant/internal/server/proto/ruby_vagrant"
)

type RubyVagrantClient struct {
	conn    *grpc.ClientConn
	client  ruby_vagrant.RubyVagrantClient
	plugins plugin.PluginSet
}

func NewRubyVagrantClient(ctx context.Context, log hclog.Logger, addr string) (*RubyVagrantClient, error) {
	log = log.Named("vagrant-ruby-runtime")
	conn, err := grpc.DialContext(ctx, addr,
		grpc.WithBlock(),
		grpc.WithInsecure(),
		grpc.WithUnaryInterceptor(protocolversion.UnaryClientInterceptor(protocolversion.Current())),
		grpc.WithStreamInterceptor(protocolversion.StreamClientInterceptor(protocolversion.Current())),
		grpc.WithChainUnaryInterceptor(
			logClientUnaryInterceptor(log, false),
		),
	)
	if err != nil {
		return nil, err
	}

	return &RubyVagrantClient{
		conn:    conn,
		client:  ruby_vagrant.NewRubyVagrantClient(conn),
		plugins: pluginclient.ClientConfig(hclog.L()).VersionedPlugins[1],
	}, nil
}

func WrapRubyVagrantClient(conn *grpc.ClientConn) *RubyVagrantClient {
	return &RubyVagrantClient{
		conn:    conn,
		client:  ruby_vagrant.NewRubyVagrantClient(conn),
		plugins: pluginclient.ClientConfig(hclog.L()).VersionedPlugins[1],
	}
}

func (r *RubyVagrantClient) Dispense(name string) (interface{}, error) {
	raw, ok := r.plugins[name]
	if !ok {
		hclog.L().Warn("unknown ruby plugin type", "name", name, "plugins", r.plugins)
		return nil, fmt.Errorf("unknown ruby runtime plugin type: %s", name)
	}

	p, ok := raw.(plugin.GRPCPlugin)
	if !ok {
		return nil, fmt.Errorf("plugin %s doesn't support ruby runtime grpc", name)
	}

	return p.GRPCClient(context.Background(), &plugin.GRPCBroker{}, r.conn)

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

func (r *RubyVagrantClient) ServerTarget() string {
	return r.conn.Target()
}
