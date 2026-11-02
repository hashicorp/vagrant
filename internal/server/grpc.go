// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"time"

	"github.com/oklog/run"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"
	"google.golang.org/protobuf/types/known/emptypb"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// grpcInit initializes the gRPC server and adds it to the run group.
func grpcInit(group *run.Group, opts *options) error {
	log := opts.Logger.Named("grpc")

	// Get our server info immediately
	resp, err := opts.Service.GetVersionInfo(opts.Context, &emptypb.Empty{})
	if err != nil {
		return err
	}

	var so []grpc.ServerOption
	so = append(so,
		grpc.ChainUnaryInterceptor(
			// Insert our logger and also log req/resp
			logUnaryInterceptor(log, false),

			// Protocol version negotiation
			versionUnaryInterceptor(resp.Info),
		),
		grpc.ChainStreamInterceptor(
			// Insert our logger and log
			logStreamInterceptor(log, false),

			// Protocol version negotiation
			versionStreamInterceptor(resp.Info),
		),
	)

	if opts.AuthChecker != nil {
		so = append(so,
			grpc.ChainUnaryInterceptor(authUnaryInterceptor(opts.AuthChecker)),
			grpc.ChainStreamInterceptor(authStreamInterceptor(opts.AuthChecker)),
		)
	}

	s := grpc.NewServer(so...)
	opts.grpcServer = s

	// Register the reflection service. This makes using tools like grpcurl
	// easier. It makes it slightly easier for malicious users to know about
	// the service but I think they'd figure out its a vagrant server
	// easy enough.
	reflection.Register(s)

	// Register our server
	vagrant_server.RegisterVagrantServer(s, opts.Service)

	// Register extra services that are configured
	for _, f := range opts.GRPCServices {
		f(s)
	}

	// Add our gRPC server to the run group
	group.Add(func() error {
		// Serve traffic
		ln := opts.GRPCListener
		log.Info("starting gRPC server", "addr", ln.Addr().String())
		return s.Serve(ln)
	}, func(err error) {
		// Graceful in a goroutine so we can timeout
		gracefulCh := make(chan struct{})
		go func() {
			defer close(gracefulCh)
			log.Info("shutting down gRPC server")
			s.GracefulStop()
		}()

		select {
		case <-gracefulCh:

		// After a timeout we just forcibly exit. Our gRPC endpoints should
		// be fairly quick and their operations are atomic so we just kill
		// the connections after a few seconds.
		case <-time.After(2 * time.Second):
			s.Stop()
		}
	})

	return nil
}
