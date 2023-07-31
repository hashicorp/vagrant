// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package runner

import (
	"context"
	"io"
	"os"
	"strings"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// watchConfig sits in a goroutine receiving the new configurations from the
// server.
func (r *Runner) watchConfig(ch <-chan *vagrant_server.RunnerConfig) {
	for config := range ch {
		r.handleConfig(config)
	}
}

// handleConfig handles the changes for a single config.
//
// This is NOT thread-safe, but it is safe to handle a configuration
// change in parallel to any other operation.
func (r *Runner) handleConfig(c *vagrant_server.RunnerConfig) {
	old := r.config
	r.config = c

	// Store our original environment as a set of config vars. This will
	// let us replace any of these later if the runtime config gets unset.
	if r.originalEnv == nil {
		r.originalEnv = []*vagrant_server.ConfigVar{}
		for _, str := range os.Environ() {
			idx := strings.Index(str, "=")
			if idx == -1 {
				continue
			}

			r.originalEnv = append(r.originalEnv, &vagrant_server.ConfigVar{
				Name:  str[:idx],
				Value: str[idx+1:],
			})
		}
	}

	// Handle config var changes
	{
		// Setup our original env. This will ensure that we replace the
		// variable if it becomes unset.
		env := map[string]string{}
		for _, v := range r.originalEnv {
			env[v.Name] = v.Value
		}

		if old != nil {
			// Unset any previous config variables. We check if its in env
			// already because if it is, it is an original value and we accept
			// that. This lets unset runtime config get reset back to the
			// original process start env.
			for _, v := range old.ConfigVars {
				if _, ok := env[v.Name]; !ok {
					env[v.Name] = ""
				}
			}
		}

		// Set the config variables
		for _, v := range c.ConfigVars {
			env[v.Name] = v.Value
		}

		// Set them all
		for k, v := range env {
			// We ignore current value so that the log doesn't look messy
			if os.Getenv(k) == v {
				continue
			}

			// Unset if empty
			if v == "" {
				r.logger.Info("unsetting env var", "key", k)
				if err := os.Unsetenv(k); err != nil {
					r.logger.Warn("error unsetting config var", "key", k, "err", err)
				}

				continue
			}

			// Set
			r.logger.Info("setting env var", "key", k)
			if err := os.Setenv(k, v); err != nil {
				r.logger.Warn("error setting config var", "key", k, "err", err)
			}
		}
	}
}

func (r *Runner) recvConfig(
	ctx context.Context,
	client vagrant_server.Vagrant_RunnerConfigClient,
	ch chan<- *vagrant_server.RunnerConfig,
) {
	log := r.logger.Named("config_recv")
	defer log.Trace("exiting receive goroutine")
	defer close(ch)

	for {
		// If the context is closed, exit
		if ctx.Err() != nil {
			return
		}

		// Wait for the next configuration
		resp, err := client.Recv()
		if err != nil {
			if err == io.EOF {
				return
			}

			log.Error("error receiving configuration, exiting", "err", err)
			return
		}

		log.Info("new configuration received")
		ch <- resp.Config
	}
}
