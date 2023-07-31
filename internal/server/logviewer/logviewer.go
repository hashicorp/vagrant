// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package logviewer

import (
	"context"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// Viewer implements component.LogViewer over the server-side log stream endpoint.
//
// TODO(mitchellh): we should support some form of reconnection in the event of
// network errors.
type Viewer struct {
	// Stream is the log stream client to use.
	Stream vagrant_server.Vagrant_GetLogStreamClient
}

// NextLogBatch implements component.LogViewer
func (v *Viewer) NextLogBatch(ctx context.Context) ([]component.LogEvent, error) {
	// Get the next batch. Note that we specifically do NOT buffer here because
	// we want to provide the proper amount of backpressure and we expect our
	// downstream caller to be calling these as quickly as possible.
	batch, err := v.Stream.Recv()
	if err != nil {
		return nil, err
	}

	events := make([]component.LogEvent, len(batch.Lines))
	for i, entry := range batch.Lines {
		ts := entry.Timestamp.AsTime()

		events[i] = component.LogEvent{
			Partition: batch.InstanceId,
			Timestamp: ts,
			Message:   entry.Line,
		}
	}

	return events, nil
}

var _ component.LogViewer = (*Viewer)(nil)
