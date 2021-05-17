package core

import (
	"github.com/hashicorp/go-plugin"
	"google.golang.org/grpc"
)

type closer interface {
	Closer(func() error)
}

type closes interface {
	Close() error
}

func wrapInstance(p plugin.GRPCPlugin, b *plugin.GRPCBroker, c closer) (uint32, error) {
	id := b.NextId()
	errChan := make(chan error, 1)

	go b.AcceptAndServe(id, func(opts []grpc.ServerOption) *grpc.Server {
		server := plugin.DefaultGRPCServer(opts)
		if err := p.GRPCServer(b, server); err != nil {
			errChan <- err
			return nil
		}
		c.Closer(func() error {
			server.GracefulStop()
			return nil
		})
		close(errChan)
		return server
	})

	err := <-errChan
	if err != nil {
		return 0, err
	}

	return id, nil
}
