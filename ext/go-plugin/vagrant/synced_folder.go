package vagrant

import (
	"context"
)

type FolderList map[string]interface{}
type FolderOptions map[string]interface{}

type SyncedFolderInfo struct {
	Description string `json:"description"`
	Priority    int64  `json:"priority"`
}

type SyncedFolder interface {
	Cleanup(ctx context.Context, m *Machine, opts FolderOptions) error
	Disable(ctx context.Context, m *Machine, f FolderList, opts FolderOptions) error
	Enable(ctx context.Context, m *Machine, f FolderList, opts FolderOptions) error
	Info() *SyncedFolderInfo
	IsUsable(ctx context.Context, m *Machine) (bool, error)
	Name() string
	Prepare(ctx context.Context, m *Machine, f FolderList, opts FolderOptions) error

	GuestCapabilities
	HostCapabilities
}
