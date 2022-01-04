package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestMachineSetValidId(t *testing.T) {
	tm, _ := TestMachine(t)

	// Set valid id
	tm.SetID("something")
	newId, err := tm.ID()
	if err != nil {
		t.Errorf("Failed to get id")
	}
	require.Equal(t, newId, "something")

	// Ensure new id is save to db
	dbTarget, err := tm.Client().GetTarget(tm.ctx,
		&vagrant_server.GetTargetRequest{
			Target: tm.Ref().(*vagrant_plugin_sdk.Ref_Target),
		},
	)
	if err != nil {
		t.Errorf("Failed to get target")
	}
	require.Equal(t, dbTarget.Target.Uuid, "something")
}

func TestMachineSetEmptyId(t *testing.T) {
	tm, _ := TestMachine(t)
	oldId := tm.target.ResourceId

	// Set empty id
	tm.SetID("")
	newId, err := tm.ID()
	if err != nil {
		t.Errorf("Failed to get id")
	}
	require.Equal(t, newId, "")

	// Ensure machine is deleted from the db by checking for the old id
	dbTarget, err := tm.Client().GetTarget(tm.ctx,
		&vagrant_server.GetTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: oldId,
				Project:    tm.target.Project,
				Name:       tm.target.Name,
			},
		},
	)
	require.Nil(t, dbTarget)
	require.Error(t, err)

	// Also check new id
	dbTarget, err = tm.Client().GetTarget(tm.ctx,
		&vagrant_server.GetTargetRequest{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: "",
				Project:    tm.target.Project,
				Name:       tm.target.Name,
			},
		},
	)
	require.Nil(t, dbTarget)
	require.Error(t, err)
}
