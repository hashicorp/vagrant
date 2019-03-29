package plugin

import (
	"context"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_io"

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

func (s *GRPCIOServer) Read(ctx context.Context, req *vagrant_io.ReadRequest) (r *vagrant_io.ReadResponse, err error) {
	r = &vagrant_io.ReadResponse{}
	n := make(chan struct{}, 1)
	go func() {
		r.Content, err = s.Impl.Read(req.Target)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCIOServer) Write(ctx context.Context, req *vagrant_io.WriteRequest) (r *vagrant_io.WriteResponse, err error) {
	r = &vagrant_io.WriteResponse{}
	n := make(chan struct{}, 1)
	bytes := 0
	go func() {
		bytes, err = s.Impl.Write(req.Content, req.Target)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
		r.Length = int32(bytes)
	}
	return
}

type GRPCIOClient struct {
	client  vagrant_io.IOClient
	doneCtx context.Context
}

func (c *GRPCIOClient) Read(target string) (content string, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Read(jctx, &vagrant_io.ReadRequest{
		Target: target})
	if err != nil {
		return content, handleGrpcError(err, c.doneCtx, ctx)
	}
	content = resp.Content
	return
}

func (c *GRPCIOClient) Write(content, target string) (length int, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Write(jctx, &vagrant_io.WriteRequest{
		Content: content,
		Target:  target})
	if err != nil {
		return length, handleGrpcError(err, c.doneCtx, ctx)
	}
	length = int(resp.Length)
	return
}

func (i *IOPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	vagrant_io.RegisterIOServer(s, &GRPCIOServer{Impl: i.Impl})
	return nil
}

func (i *IOPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	return &GRPCIOClient{
		client:  vagrant_io.NewIOClient(c),
		doneCtx: ctx}, nil
}
