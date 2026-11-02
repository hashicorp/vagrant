// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package server

import (
	"context"
	"net"
	"net/http"
	//"strings"
	"time"

	//assetfs "github.com/elazarl/go-bindata-assetfs"
	//	"github.com/hashicorp/vagrant/internal/server/gen/vagrant_server"
	"github.com/improbable-eng/grpc-web/go/grpcweb"
	"github.com/oklog/run"
)

// httpInit initializes the HTTP server and adds it to the run group.
func httpInit(group *run.Group, opts *options) error {
	log := opts.Logger.Named("http")
	if opts.HTTPListener == nil {
		log.Info("HTTP listener not specified, HTTP API is disabled")
		return nil
	}

	// Wrap the grpc server so that it is grpc-web compatible
	grpcWrapped := grpcweb.WrapServer(opts.grpcServer,
		grpcweb.WithCorsForRegisteredEndpointsOnly(false),
		grpcweb.WithOriginFunc(func(string) bool { return true }),
		grpcweb.WithAllowNonRootResource(true),
	)

	// TODO: ember stuff
	// uifs := http.FileServer(&assetfs.AssetFS{
	// 	Asset:     vagrant_server.Asset,
	// 	AssetDir:  vagrant_server.AssetDir,
	// 	AssetInfo: vagrant_server.AssetInfo,
	// 	Prefix:    "ui/dist",
	// 	Fallback:  "index.html",
	// })

	// If the path has a grpc prefix we assume it's a GRPC gateway request,
	// otherwise fall back to serving the UI from the filesystem
	rootHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// if strings.HasPrefix(r.URL.Path, "/grpc") {
		grpcWrapped.ServeHTTP(w, r)
		// } else if opts.BrowserUIEnabled {
		//	uifs.ServeHTTP(w, r)
		// }
	})

	// Create our http server
	httpSrv := &http.Server{
		ReadHeaderTimeout: 5 * time.Second,
		IdleTimeout:       120 * time.Second,
		Handler:           httpLogHandler(rootHandler, log),
		BaseContext: func(net.Listener) context.Context {
			return opts.Context
		},
	}

	// Add our gRPC server to the run group
	group.Add(func() error {
		// Serve traffic
		ln := opts.HTTPListener
		log.Info("starting HTTP server", "addr", ln.Addr().String())
		return httpSrv.Serve(ln)
	}, func(err error) {
		ctx, cancelFunc := context.WithCancel(context.Background())
		defer cancelFunc()

		// Graceful in a goroutine so we can timeout
		gracefulCh := make(chan struct{})
		go func() {
			defer close(gracefulCh)
			log.Info("shutting down HTTP server")
			httpSrv.Shutdown(ctx)
		}()

		select {
		case <-gracefulCh:

		// After a timeout we just forcibly exit. Our HTTP endpoints should
		// be fairly quick and their operations are atomic so we just kill
		// the connections after a few seconds.
		case <-time.After(2 * time.Second):
			cancelFunc()
		}
	})

	return nil
}
