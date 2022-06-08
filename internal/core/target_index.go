package core

import (
	"context"
	"fmt"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/serverclient"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/emptypb"
)

// TargetIndex represents
type TargetIndex struct {
	ctx    context.Context
	logger hclog.Logger

	client *serverclient.VagrantClient

	basis *Basis
	// The below are resources we need to close when Close is called, if non-nil
	closers []func() error
}

func (t *TargetIndex) Delete(uuid string) (err error) {
	target, err := t.Get(uuid)
	if err != nil {
		if codes.NotFound == status.Code(err) {
			return nil
		}
		return err
	}

	return target.(*Target).Destroy()
}

// Get target from entry by uuid or name
func (t *TargetIndex) Get(uuid string) (entry core.Target, err error) {
	// Start with finding the target
	result, err := t.client.FindTarget(t.ctx, &vagrant_server.FindTargetRequest{
		Target: &vagrant_server.Target{
			Uuid: uuid,
		},
	})
	if err != nil {
		return
	}
	return t.loadTarget(&vagrant_plugin_sdk.Ref_Target{
		ResourceId: result.Target.ResourceId,
	})
}

func (t *TargetIndex) Includes(uuid string) (exists bool, err error) {
	_, err = t.Get(uuid)
	if err != nil {
		if codes.NotFound == status.Code(err) {
			return false, nil
		}

		return
	}
	return true, nil
}

func (t *TargetIndex) Set(entry core.Target) (updatedEntry core.Target, err error) {
	updatedEntry, ok := entry.(*Target)
	if !ok {
		return nil, fmt.Errorf("cannot save target, invalid type. Target %v, type %v",
			entry, hclog.Fmt("%T", entry),
		)
	}

	err = updatedEntry.Save()
	return
}

func (t *TargetIndex) All() (targets []core.Target, err error) {
	list, err := t.client.ListTargets(t.ctx, &emptypb.Empty{})
	if err != nil {
		return
	}

	targets = []core.Target{}
	for _, tInfo := range list.Targets {
		nt, err := t.loadTarget(tInfo)
		if err != nil {
			return nil, err
		}
		targets = append(targets, nt)
	}

	return
}

func (t *TargetIndex) Close() (err error) {
	return
}

func (t *TargetIndex) loadTarget(tproto *vagrant_plugin_sdk.Ref_Target) (target *Target, err error) {
	gt, err := t.client.GetTarget(t.ctx, &vagrant_server.GetTargetRequest{
		Target: tproto,
	})
	if err != nil {
		return
	}
	info := gt.Target
	// Load the project
	p, err := t.basis.LoadProject(WithProjectRef(info.Project))
	if err != nil {
		return
	}
	// Finally, load the target
	return p.LoadTarget(
		WithTargetRef(tproto),
	)
}

var _ core.TargetIndex = (*TargetIndex)(nil)
