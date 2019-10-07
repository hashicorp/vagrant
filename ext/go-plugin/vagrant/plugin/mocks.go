package plugin

import (
	"context"
	"errors"
	"time"

	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
)

type MockGuestCapabilities struct{ Core }

func (g *MockGuestCapabilities) GuestCapabilities() (caps []vagrant.SystemCapability, err error) {
	caps = []vagrant.SystemCapability{
		vagrant.SystemCapability{Name: "test_cap", Platform: "testOS"}}
	return
}

func (g *MockGuestCapabilities) GuestCapability(ctx context.Context, cap *vagrant.SystemCapability, args interface{}, m *vagrant.Machine) (result interface{}, err error) {
	if args != nil {
		arguments := args.([]interface{})
		if arguments[0] == "pause" {
			time.Sleep(1 * time.Second)
		}
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

func (h *MockHostCapabilities) HostCapability(ctx context.Context, cap *vagrant.SystemCapability, args interface{}, e *vagrant.Environment) (result interface{}, err error) {
	if args != nil {
		arguments := args.([]interface{})
		if arguments[0] == "pause" {
			time.Sleep(1 * time.Second)
		}
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

func (p *MockProviderCapabilities) ProviderCapability(ctx context.Context, cap *vagrant.ProviderCapability, args interface{}, m *vagrant.Machine) (result interface{}, err error) {
	if args != nil {
		arguments := args.([]interface{})
		if arguments[0] == "pause" {
			time.Sleep(1 * time.Second)
		}
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

func (c *MockConfig) ConfigLoad(ctx context.Context, data map[string]interface{}) (loaddata map[string]interface{}, err error) {
	if data["pause"] == true {
		time.Sleep(1 * time.Second)
	}
	loaddata = map[string]interface{}{
		"test_key": "test_val"}
	if data["test_key"] != nil {
		loaddata["sent_key"] = data["test_key"]
	}
	return
}

func (c *MockConfig) ConfigValidate(ctx context.Context, data map[string]interface{}, m *vagrant.Machine) (errors []string, err error) {
	errors = []string{"test error"}
	if data["pause"] == true {
		time.Sleep(1 * time.Second)
	}
	return
}

func (c *MockConfig) ConfigFinalize(ctx context.Context, data map[string]interface{}) (finaldata map[string]interface{}, err error) {
	finaldata = make(map[string]interface{})
	for key, tval := range data {
		val, ok := tval.(string)
		if !ok {
			continue
		}
		finaldata[key] = val + "-updated"
	}
	if data["pause"] == true {
		time.Sleep(1 * time.Second)
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

func (c *MockProvider) Action(ctx context.Context, actionName string, m *vagrant.Machine) (actions []string, err error) {
	switch actionName {
	case "valid":
		actions = []string{"self::DoTask"}
	case "pause":
		time.Sleep(1 * time.Second)
	default:
		err = errors.New("Unknown action requested")
	}
	return
}

func (c *MockProvider) IsInstalled(ctx context.Context, m *vagrant.Machine) (bool, error) {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	return true, nil
}

func (c *MockProvider) IsUsable(ctx context.Context, m *vagrant.Machine) (bool, error) {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	return true, nil
}

func (c *MockProvider) MachineIdChanged(ctx context.Context, m *vagrant.Machine) error {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	return nil
}

func (c *MockProvider) Name() string {
	return "mock_provider"
}

func (c *MockProvider) RunAction(ctx context.Context, actionName string, args interface{}, m *vagrant.Machine) (r interface{}, err error) {
	switch actionName {
	case "send_output":
		m.UI.Say("test_output_p")
	case "pause":
		time.Sleep(1 * time.Second)
	case "valid":
	default:
		return nil, errors.New("invalid action name")
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

func (c *MockProvider) SshInfo(ctx context.Context, m *vagrant.Machine) (*vagrant.SshInfo, error) {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	return &vagrant.SshInfo{
		Host: "localhost",
		Port: 2222}, nil
}

func (c *MockProvider) State(ctx context.Context, m *vagrant.Machine) (*vagrant.MachineState, error) {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

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

func (s *MockSyncedFolder) Cleanup(ctx context.Context, m *vagrant.Machine, opts vagrant.FolderOptions) error {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

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

func (s *MockSyncedFolder) Disable(ctx context.Context, m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	if opts != nil && opts["error"].(bool) {
		return errors.New("disable error")
	}
	return nil
}

func (s *MockSyncedFolder) Enable(ctx context.Context, m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

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

func (s *MockSyncedFolder) IsUsable(ctx context.Context, m *vagrant.Machine) (bool, error) {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	return true, nil
}

func (s *MockSyncedFolder) Name() string {
	return "mock_folder"
}

func (s *MockSyncedFolder) Prepare(ctx context.Context, m *vagrant.Machine, f vagrant.FolderList, opts vagrant.FolderOptions) error {
	if m.Name == "pause" {
		time.Sleep(1 * time.Second)
	}

	if opts != nil && opts["error"].(bool) {
		return errors.New("prepare error")
	}
	return nil
}
