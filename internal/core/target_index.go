package core

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
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

func (m *TargetIndex) Delete(machine core.Machine) (err error) {
	return nil
}

func (m *TargetIndex) Get(uuid string) (entry core.Machine, err error) {
	return nil, nil
}

func (m *TargetIndex) Includes(uuid string) (exists bool, err error) {
	return false, nil
}

func (m *TargetIndex) Set(entry core.Machine) (updatedEntry core.Machine, err error) {
	return nil, nil
}

func (m *TargetIndex) Recover(entry core.Machine) (updatedEntry core.Machine, err error) {
	return nil, nil
}

var _ core.TargetIndex = (*TargetIndex)(nil)
