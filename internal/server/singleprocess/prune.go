// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package singleprocess

import (
	"context"
	"sync"
	"time"

	"github.com/hashicorp/go-hclog"
)

func (s *service) runPrune(
	ctx context.Context,
	wg *sync.WaitGroup,
	funclog hclog.Logger,
) {
	defer wg.Done()

	funclog.Info("starting")
	defer funclog.Info("exiting")

	tk := time.NewTicker(10 * time.Minute)
	defer tk.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-tk.C:
			err := s.state.Prune()
			if err != nil {
				funclog.Error("error pruning data", "error", err)
			}
		}
	}
}
