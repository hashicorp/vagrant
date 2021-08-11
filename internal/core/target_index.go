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

	client  *serverclient.VagrantClient
	project *Project
	// The below are resources we need to close when Close is called, if non-nil
	closers []func() error
}

func (t *TargetIndex) Delete(uuid string) (err error) {
	_, err = t.client.DeleteTarget(
		t.ctx,
		&vagrant_server.DeleteTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{ResourceId: uuid},
		},
	)
	return
}

func (t *TargetIndex) Get(uuid string) (entry core.Target, err error) {
	return t.project.Target(uuid)
}

func (t *TargetIndex) Includes(uuid string) (exists bool, err error) {
	_, err = t.project.Target(uuid)
	if err == nil {
		return true, nil
	}
	return false, nil
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
