package plugin

import (
	"context"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto"

	"github.com/LK4D4/joincontext"
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

func (s *GRPCIOServer) Read(ctx context.Context, req *vagrant_proto.Identifier) (r *vagrant_proto.Content, err error) {
	r = &vagrant_proto.Content{}
	r.Value, err = s.Impl.Read(req.Name)
	return
}

func (s *GRPCIOServer) Write(ctx context.Context, req *vagrant_proto.Content) (r *vagrant_proto.WriteResponse, err error) {
	r = &vagrant_proto.WriteResponse{}
	bytes := 0
	bytes, err = s.Impl.Write(req.Value, req.Target)
	if err != nil {
		return
	}
	r.Length = int32(bytes)
	return
}

type GRPCIOClient struct {
	client  vagrant_proto.IOClient
	doneCtx context.Context
}

func (c *GRPCIOClient) Read(target string) (content string, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Read(jctx, &vagrant_proto.Identifier{
		Name: target})
	if err != nil {
		return content, handleGrpcError(err, c.doneCtx, ctx)
	}
	content = resp.Value
	return
}

func (c *GRPCIOClient) Write(content, target string) (length int, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Write(jctx, &vagrant_proto.Content{
		Value:  content,
		Target: target})
	if err != nil {
		return length, handleGrpcError(err, c.doneCtx, ctx)
	}
	length = int(resp.Length)
	return
}

func (i *IOPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	vagrant_proto.RegisterIOServer(s, &GRPCIOServer{Impl: i.Impl})
	return nil
}

func (i *IOPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	return &GRPCIOClient{
		client:  vagrant_proto.NewIOClient(c),
		doneCtx: ctx}, nil
}
