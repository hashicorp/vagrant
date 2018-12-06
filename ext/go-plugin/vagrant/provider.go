package vagrant

type Provider interface {
	Info() *ProviderInfo
	Action(actionName string, machData *Machine) ([]string, error)
	IsInstalled(machData *Machine) (bool, error)
	IsUsable(machData *Machine) (bool, error)
	MachineIdChanged(machData *Machine) error
	Name() string
	RunAction(actionName string, data string, machData *Machine) (string, error)
	SshInfo(machData *Machine) (*SshInfo, error)
	State(machData *Machine) (*MachineState, error)

	Config
	GuestCapabilities
	HostCapabilities
	ProviderCapabilities
}

type ProviderInfo struct {
	Description string `json:"description"`
	Priority    int64  `json:"priority"`
}
