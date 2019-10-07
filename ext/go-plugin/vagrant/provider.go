package vagrant

import (
	"context"
)

type Provider interface {
	Info() *ProviderInfo
	Action(ctx context.Context, actionName string, machData *Machine) ([]string, error)
	IsInstalled(ctx context.Context, machData *Machine) (bool, error)
	IsUsable(ctx context.Context, machData *Machine) (bool, error)
	MachineIdChanged(ctx context.Context, machData *Machine) error
	Name() string
	RunAction(ctx context.Context, actionName string, args interface{}, machData *Machine) (interface{}, error)
	SshInfo(ctx context.Context, machData *Machine) (*SshInfo, error)
	State(ctx context.Context, machData *Machine) (*MachineState, error)

	Config
	GuestCapabilities
	HostCapabilities
	ProviderCapabilities
}

type ProviderInfo struct {
	Description string `json:"description"`
	Priority    int64  `json:"priority"`
}
