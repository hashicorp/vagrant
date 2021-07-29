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
	// This is not going to work since no deleting requires
	// also having a project to delete a target from.
	// Doesn't seem possible to get a project id from a core component
	tid, err := target.ResourceId()
	if err != nil {
		return err
	}
	tname, err := target.Name()
	if err != nil {
		return err
	}
	_, err = t.client.DeleteTarget(
		t.ctx,
		&vagrant_server.DeleteTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: tid,
				Name:       tname,
				// Project: &vagrant_plugin_sdk.Ref_Project{}
			},
		},
	)
	return
}

func (m *TargetIndex) Get(uuid string) (entry core.Target, err error) {
	return nil, nil
}

func (m *TargetIndex) Includes(uuid string) (exists bool, err error) {
	return false, nil
}

func (t *TargetIndex) Set(entry core.Target) (updatedEntry core.Target, err error) {
	// updatedTarget, err = t.client.UpsertTarget(
	// 	t.ctx,
	// 	&vagrant_server.UpsertTargetRequest{
	// 		Target: &vagrant_server.Target{},
	// 	},
	// )
	return
}

func (m *TargetIndex) Recover(entry core.Target) (updatedEntry core.Target, err error) {
	return nil, nil
}

var _ core.TargetIndex = (*TargetIndex)(nil)
