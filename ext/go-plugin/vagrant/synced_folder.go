package vagrant

type FolderList map[string]interface{}
type FolderOptions map[string]interface{}

type SyncedFolderInfo struct {
	Description string `json:"description"`
	Priority    int64  `json:"priority"`
}

type SyncedFolder interface {
	Cleanup(m *Machine, opts *FolderOptions) error
	Disable(m *Machine, f *FolderList, opts *FolderOptions) error
	Enable(m *Machine, f *FolderList, opts *FolderOptions) error
	Info() *SyncedFolderInfo
	IsUsable(m *Machine) (bool, error)
	Name() string
	Prepare(m *Machine, f *FolderList, opts *FolderOptions) error

	GuestCapabilities
	HostCapabilities
}
