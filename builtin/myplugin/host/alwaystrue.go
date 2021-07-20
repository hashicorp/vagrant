package host

import (
	"errors"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
	"github.com/hashicorp/vagrant/builtin/myplugin/host/cap"
)

type HostConfig struct {
}

// AlwaysTrueHost is a Host implementation for myplugin.
type AlwaysTrueHost struct {
	config HostConfig
}

// DetectFunc implements component.Host
func (h *AlwaysTrueHost) DetectFunc() interface{} {
	return h.Detect
}

func (h *AlwaysTrueHost) Detect() bool {
	return true
}

// ParentsFunc implements component.Host
func (h *AlwaysTrueHost) ParentsFunc() interface{} {
	return h.Parents
}

func (h *AlwaysTrueHost) Parents() []string {
	return []string{"force", "host", "platform", "match"} // We just need to have this be the most of all matches
}

// HasCapabilityFunc implements component.Host
func (h *AlwaysTrueHost) HasCapabilityFunc() interface{} {
	return h.CheckCapability
}

func (h *AlwaysTrueHost) CheckCapability(n *component.NamedCapability) bool {
	if n.Capability == "write_hello" {
		return true
	}
	return false
}

// CapabilityFunc implements component.Host
func (h *AlwaysTrueHost) CapabilityFunc(name string) interface{} {
	if name == "write_hello" {
		return h.WriteHelloCap
	}
	return errors.New("Invalid capability requested")
}

func (h *AlwaysTrueHost) WriteHelloCap(ui terminal.UI) error {
	return cap.WriteHello(ui)
}

var (
	_ component.Host = (*AlwaysTrueHost)(nil)
)
