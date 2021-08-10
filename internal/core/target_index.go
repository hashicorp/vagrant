package core

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
	"github.com/mitchellh/mapstructure"
)

// TargetIndex represents
type TargetIndex struct {
	ctx    context.Context
	logger hclog.Logger

	client  *serverclient.VagrantClient
	project *Project
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
	return t.project.Target(ref.Name)
}

func (t *TargetIndex) Includes(ref *vagrant_plugin_sdk.Ref_Target) (exists bool, err error) {
	var req *vagrant_server.Target
	mapstructure.Decode(ref, &req)
	resp, err := t.client.FindTarget(
		t.ctx,
		&vagrant_server.FindTargetRequest{
			Target: req,
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
	target := entry.(*Target)
	updatedTarget, err := t.client.UpsertTarget(
		t.ctx,
		&vagrant_server.UpsertTargetRequest{
			Target: target.target,
		},
	)
	updatedEntry, err = NewTarget(
		t.ctx,
		WithTargetName(updatedTarget.Target.Name),
	)
	return
}

func (t *TargetIndex) All() (targets []core.Target, err error) {
	return t.project.Targets()
}

var _ core.TargetIndex = (*TargetIndex)(nil)
