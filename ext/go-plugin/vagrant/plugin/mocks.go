package plugin

import (
	"errors"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

type MockGuestCapabilities struct{ Core }

func (g *MockGuestCapabilities) GuestCapabilities() (caps []vagrant.SystemCapability, err error) {
	caps = []vagrant.SystemCapability{
		vagrant.SystemCapability{Name: "test_cap", Platform: "testOS"}}
	return
}

func (g *MockGuestCapabilities) GuestCapability(cap *vagrant.SystemCapability, args interface{}, m *vagrant.Machine) (result interface{}, err error) {
	if args != nil {
		arguments := args.([]interface{})
		if len(arguments) > 0 {
			result = []string{
				cap.Name,
				arguments[0].(string)}
			return
		}
	}
	result = []string{cap.Name}
	return
}

type MockHostCapabilities struct{ Core }

func (h *MockHostCapabilities) HostCapabilities() (caps []vagrant.SystemCapability, err error) {
	caps = []vagrant.SystemCapability{
		vagrant.SystemCapability{Name: "test_cap", Platform: "testOS"}}
	return
}

func (h *MockHostCapabilities) HostCapability(cap *vagrant.SystemCapability, args interface{}, e *vagrant.Environment) (result interface{}, err error) {
	if args != nil {
		arguments := args.([]interface{})
		if len(arguments) > 0 {
			result = []string{
				cap.Name,
				arguments[0].(string)}
			return
		}
	}
	result = []string{cap.Name}
	return
}

type MockProviderCapabilities struct{ Core }

func (p *MockProviderCapabilities) ProviderCapabilities() (caps []vagrant.ProviderCapability, err error) {
	caps = []vagrant.ProviderCapability{
		vagrant.ProviderCapability{Name: "test_cap", Provider: "testProvider"}}
	return
}

func (p *MockProviderCapabilities) ProviderCapability(cap *vagrant.ProviderCapability, args interface{}, m *vagrant.Machine) (result interface{}, err error) {
	if args != nil {
		arguments := args.([]interface{})
		if len(arguments) > 0 {
			result = []string{
				cap.Name,
				arguments[0].(string)}
			return
		}
	}
	result = []string{cap.Name}
	return
}

type MockConfig struct {
	Core
}

func (c *MockConfig) ConfigAttributes() (attrs []string, err error) {
	attrs = []string{"fubar", "foobar"}
	return
}

func (c *MockConfig) ConfigLoad(data map[string]interface{}) (loaddata map[string]interface{}, err error) {
	loaddata = map[string]interface{}{
		"test_key": "test_val"}
	if data["test_key"] != nil {
		loaddata["sent_key"] = data["test_key"]
	}
	return
}

func (c *MockConfig) ConfigValidate(data map[string]interface{}, m *vagrant.Machine) (errors []string, err error) {
	errors = []string{"test error"}
	return
}

func (c *MockConfig) ConfigFinalize(data map[string]interface{}) (finaldata map[string]interface{}, err error) {
	finaldata = make(map[string]interface{})
	for key, tval := range data {
		val := tval.(string)
		finaldata[key] = val + "-updated"
	}
	return
}

type MockProvider struct {
	Core
	vagrant.NoConfig
	vagrant.NoGuestCapabilities
	vagrant.NoHostCapabilities
	vagrant.NoProviderCapabilities
}

func (c *MockProvider) Action(actionName string, m *vagrant.Machine) (actions []string, err error) {
	if actionName == "valid" {
		actions = []string{"self::DoTask"}
	} else {
		err = errors.New("Unknown action requested")
	}
	return
}

func (c *MockProvider) IsInstalled(m *vagrant.Machine) (bool, error) {
	return true, nil
}

func (c *MockProvider) IsUsable(m *vagrant.Machine) (bool, error) {
	return true, nil
}

func (c *MockProvider) MachineIdChanged(m *vagrant.Machine) error {
	return nil
}

func (c *MockProvider) Name() string {
	return "mock_provider"
}

func (c *MockProvider) RunAction(actionName string, args interface{}, m *vagrant.Machine) (r interface{}, err error) {
	if actionName != "valid" && actionName != "send_output" {
		err = errors.New("invalid action name")
		return
	}
	if actionName == "send_output" {
		m.UI.Say("test_output_p")
	}
	var arguments []interface{}
	if args != nil {
		arguments = args.([]interface{})
	} else {
		arguments = []interface{}{"unset"}
	}
	r = []string{
		actionName,
		arguments[0].(string)}
	return
}

func (c *MockProvider) SshInfo(m *vagrant.Machine) (*vagrant.SshInfo, error) {
	return &vagrant.SshInfo{
		Host: "localhost",
		Port: 2222}, nil
}

func (c *MockProvider) State(m *vagrant.Machine) (*vagrant.MachineState, error) {
	return &vagrant.MachineState{
		Id:        "default",
		ShortDesc: "running"}, nil
}

func (c *MockProvider) Info() *vagrant.ProviderInfo {
	return &vagrant.ProviderInfo{
		Description: "Custom",
		Priority:    10}
}

type MockSyncedFolder struct {
	Core
	vagrant.NoGuestCapabilities
	vagrant.NoHostCapabilities
}

func (s *MockSyncedFolder) Cleanup(m *vagrant.Machine, opts vagrant.FolderOptions) error {
	if opts != nil {
		err, _ := opts["error"].(bool)
		ui, _ := opts["ui"].(bool)
		if err {
			return errors.New("cleanup error")
		}
		if ui {
			m.UI.Say("test_output_sf")
			return nil
		}
	}
	return nil
}

func (s *MockSyncedFolder) Disable(m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if opts != nil && opts["error"].(bool) {
		return errors.New("disable error")
	}
	return nil
}

func (s *MockSyncedFolder) Enable(m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if opts != nil && opts["error"].(bool) {
		return errors.New("enable error")
	}
	return nil
}

func (s *MockSyncedFolder) Info() *vagrant.SyncedFolderInfo {
	return &vagrant.SyncedFolderInfo{
		Description: "mock_folder",
		Priority:    100}
}

func (s *MockSyncedFolder) IsUsable(m *vagrant.Machine) (bool, error) {
	return true, nil
}

func (s *MockSyncedFolder) Name() string {
	return "mock_folder"
}

func (s *MockSyncedFolder) Prepare(m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if opts != nil && opts["error"].(bool) {
		return errors.New("prepare error")
	}
	return nil
}
