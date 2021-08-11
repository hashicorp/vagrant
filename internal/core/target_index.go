package core

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
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

func (t *TargetIndex) Delete(ref *core.TargetRef) (err error) {
	_, err = t.client.DeleteTarget(
		t.ctx,
		&vagrant_server.DeleteTargetRequest{
			Target: ref.Ref(),
		},
	)
	return
}

func (t *TargetIndex) Get(ref *core.TargetRef) (entry core.Target, err error) {
	entry, err = t.project.Target(ref.Name)
	if err != nil {
		entry, err = t.project.Target(ref.ResourceId)
		return
	}
	return
}

func (t *TargetIndex) Includes(ref *core.TargetRef) (exists bool, err error) {
	var req *vagrant_server.Target
	mapstructure.Decode(ref, &req)
	// TODO: Not sure if this interface is going to change,
	// would be neat if FindTarget accepted a Ref_Target
	_, err = t.client.FindTarget(
		t.ctx,
		&vagrant_server.FindTargetRequest{
			Target: req,
		},
	)
	// TODO: Not sure what should  be returned by the api
	// if there is not Target found. For now assuming that
	// if a target is not found an error is returned
	if err != nil {
		return false, err
	}
	return true, err
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
