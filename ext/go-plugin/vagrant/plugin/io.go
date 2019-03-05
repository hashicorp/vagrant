package plugin

import (
	"context"
	"errors"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_io"
)

type IO interface {
	vagrant.StreamIO
}

type IOPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl vagrant.StreamIO
}

type GRPCIOServer struct {
	Impl vagrant.StreamIO
}

func (s *GRPCIOServer) Read(ctx context.Context, req *vagrant_io.ReadRequest) (*vagrant_io.ReadResponse, error) {
	r, e := s.Impl.Read(req.Target)
	result := &vagrant_io.ReadResponse{Content: r}
	if e != nil {
		result.Error = e.Error()
	}
	return result, nil
}

func (s *GRPCIOServer) Write(ctx context.Context, req *vagrant_io.WriteRequest) (*vagrant_io.WriteResponse, error) {
	n, e := s.Impl.Write(req.Content, req.Target)
	result := &vagrant_io.WriteResponse{Length: int32(n)}
	if e != nil {
		result.Error = e.Error()
	}
	return result, nil
}

type GRPCIOClient struct {
	client vagrant_io.IOClient
}

func (c *GRPCIOClient) Read(target string) (content string, err error) {
	resp, err := c.client.Read(context.Background(), &vagrant_io.ReadRequest{
		Target: target})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	content = resp.Content
	return
}

func (c *GRPCIOClient) Write(content, target string) (length int, err error) {
	resp, err := c.client.Write(context.Background(), &vagrant_io.WriteRequest{
		Content: content,
		Target:  target})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	length = int(resp.Length)
	return
}

func (i *IOPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	vagrant_io.RegisterIOServer(s, &GRPCIOServer{Impl: i.Impl})
	return nil
}

func (i *IOPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	return &GRPCIOClient{client: vagrant_io.NewIOClient(c)}, nil
}
