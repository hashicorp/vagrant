// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"context"
	"fmt"
	"reflect"

	"github.com/hashicorp/go-hclog"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/internal/config"
	"github.com/hashicorp/vagrant/internal/pkg/finalcontext"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

type scope interface {
	UI() (terminal.UI, error)
	Ref() interface{}
	JobInfo() *component.JobInfo
	Client() *serverclient.VagrantClient
	execHook(ctx context.Context, log hclog.Logger, h *config.Hook) (err error)
}

// operation is a private interface that we implement for "operations" such
// as build, deploy, push, etc. This lets us share logic around creating
// server metadata, error checking, etc.
type operation interface {
	// Init returns a new metadata message we'll upsert
	Init(scope) (proto.Message, error)

	// Upsert performs an upsert operation for some metadata
	Upsert(context.Context, vagrant_server.VagrantClient, proto.Message) (proto.Message, error)

	// Do performs the actual operation and returns the result that you
	// want to return from the operation. This result will be marshaled into
	// the ValuePtr if it implements ProtoMarshaler.
	// Do can alter the proto.Message into it's final form, as it's the value
	// returned by Init and that will be written back via Upsert after Do
	// has completed.
	Do(context.Context, hclog.Logger, scope, proto.Message) (interface{}, error)

	// StatusPtr and ValuePtr return pointers to the fields in the message
	// for the status and values respectively.
	StatusPtr(proto.Message) **vagrant_server.Status
	ValuePtr(proto.Message) **anypb.Any

	// Hooks are the hooks to execute as part of this operation keyed by "when"
	Hooks(scope) map[string][]*config.Hook

	// Labels is called to return any labels that should be set for this
	// operation. This should include the component labels. These will be merged
	// with any resulting labels from the operation.
	Labels(scope) map[string]string
}

func doOperation(
	ctx context.Context,
	log hclog.Logger,
	s scope,
	op operation,
) (interface{}, proto.Message, error) {
	// Get our hooks
	hooks := op.Hooks(s)

	// Init the metadata
	msg, err := op.Init(s)
	if err != nil {
		return nil, nil, err
	}

	// Setup our job id if we have that field.
	if f := msgField(msg, "JobId"); f.IsValid() {
		f.Set(reflect.ValueOf(s.JobInfo().Id))
	}

	// If we have no status pointer, then we just allocate one for this
	// function. We don't send this anywhere but this just lets us follow
	// the remaining logic without a bunch of nil checks.
	statusPtr := op.StatusPtr(msg)
	if statusPtr == nil {
		var status *vagrant_server.Status
		statusPtr = &status
	}
	*statusPtr = server.NewStatus(vagrant_server.Status_RUNNING)

	// Upsert the metadata for our running state
	log.Debug("creating metadata on server")
	msg, err = op.Upsert(ctx, s.Client(), msg)
	if err != nil {
		return nil, nil, err
	}
	if id := msgId(msg); id != "" {
		log = log.With("id", id)
	}

	// Reset the status pointer because we might have a new message type
	if ptr := op.StatusPtr(msg); ptr != nil {
		statusPtr = ptr
	}

	// Get where we'll set the value. Similar to statusPtr, we set this
	// to a local value if we get nil so that we can avoid nil checks.
	valuePtr := op.ValuePtr(msg)
	if valuePtr == nil {
		var value *anypb.Any
		valuePtr = &value
	}

	var doErr error

	// If we have before hooks, run those
	for i, h := range hooks["before"] {
		if err := s.execHook(ctx, log.Named(fmt.Sprintf("hook-before-%d", i)), h); err != nil {
			doErr = fmt.Errorf("Error running before hook index %d: %w", i, err)
			log.Warn("error running before hook", "err", err)

			if h.ContinueOnFailure() {
				log.Info("hook configured to continueon failure, ignoring error")
				doErr = nil
			}
		}
	}

	// Run the actual implementation
	var result interface{}
	if doErr == nil {
		log.Debug("running local operation")
		result, doErr = op.Do(ctx, log, s, msg)
		if doErr == nil {
			// No error, our state is success
			server.StatusSetSuccess(*statusPtr)

			// Set our final value if we have a value pointer
			*valuePtr = nil
			if result != nil {
				*valuePtr, err = component.ProtoAny(result)
				if err != nil {
					doErr = err
				}
			}
		}
	}

	// Run after hooks
	if doErr == nil {
		for i, h := range hooks["after"] {
			if err := s.execHook(ctx, log.Named(fmt.Sprintf("hook-after-%d", i)), h); err != nil {
				doErr = fmt.Errorf("Error running after hook index %d: %w", i, err)
				log.Warn("error running after hook", "err", err)

				if h.ContinueOnFailure() {
					log.Info("hook configured to continueon failure, ignoring error")
					doErr = nil
				}
			}
		}
	}

	// If we have an error, then we set the error status
	if doErr != nil {
		log.Warn("error during local operation", "err", doErr)
		*valuePtr = nil
		server.StatusSetError(*statusPtr, doErr)
	}

	// If our context ended we need to create a final context so we
	// can attempt to finalize our metadata.
	if ctx.Err() != nil {
		var cancel context.CancelFunc
		ctx, cancel = finalcontext.Context(log)
		defer cancel()
	}

	// Set the final metadata
	msg, err = op.Upsert(ctx, s.Client(), msg)
	if err != nil {
		log.Warn("error marking server metadata as complete", "err", err)
	} else {
		log.Debug("metadata marked as complete")
	}

	// If we had an original error, return it now that we have saved all metadata
	if doErr != nil {
		return nil, nil, doErr
	}

	return result, msg, nil
}

// msgId gets the id of the message by looking for the "Id" field. This
// will return empty string if the ID field can't be found for any reason.
func msgId(msg proto.Message) string {
	val := msgField(msg, "Id")
	if !val.IsValid() || val.Kind() != reflect.String {
		return ""
	}

	return val.String()
}

// msgField gets the field from the given message. This will return an
// invalid value if it doesn't exist.
func msgField(msg proto.Message, f string) reflect.Value {
	val := reflect.ValueOf(msg)
	if val.Kind() == reflect.Ptr {
		val = val.Elem()
	}

	// Get the Id field
	return val.FieldByName(f)
}

var _ scope = (*Basis)(nil)
var _ scope = (*Project)(nil)
var _ scope = (*Target)(nil)
