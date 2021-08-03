package core

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
)

// TargetIndex represents
type TargetIndex struct {
	ctx    context.Context
	logger hclog.Logger

	client *serverclient.VagrantClient
	// The below are resources we need to close when Close is called, if non-nil
	closers []func() error
}

func (t *TargetIndex) Delete(target core.Target) (err error) {
	_, err = t.client.DeleteTarget(
		t.ctx,
		&vagrant_server.DeleteTargetRequest{
			Target: target.Ref().(*vagrant_plugin_sdk.Ref_Target),
		},
	)
	return
}

func (t *TargetIndex) Get(ref *vagrant_plugin_sdk.Ref_Target) (entry core.Target, err error) {
	// TODO: check if this actually gets back a full target
	entry, err = NewTarget(
		t.ctx,
		WithTargetRef(ref),
	)
	return
}

func (t *TargetIndex) Includes(ref *vagrant_plugin_sdk.Ref_Target) (exists bool, err error) {
	resp, err := t.client.GetTarget(
		t.ctx,
		&vagrant_server.GetTargetRequest{
			Target: ref,
		},
	)
	if err != nil {
		return false, err
	}
	// TODO: Not sure what should  be returned by the api
	// if there is not Target found. For now assuming that
	// if a target is not found, no error is returned,
	// and the resp is nil
	if resp == nil {
		exists = false
	} else {
		exists = true
	}
	return
}

func (t *TargetIndex) Set(entry core.Target) (updatedEntry core.Target, err error) {
	updatedTarget, err := t.client.UpsertTarget(
		t.ctx,
		&vagrant_server.UpsertTargetRequest{
			Target: &vagrant_server.Target{},
		},
	)
	// TODO: check if this actually gets back a full target
	updatedEntry, err = NewTarget(
		t.ctx,
		WithTargetName(updatedTarget.Target.Name),
	)
	return
}

var _ core.TargetIndex = (*TargetIndex)(nil)
