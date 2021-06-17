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

func (h *AlwaysTrueHost) HasCapabilityFunc() interface{} {
	return h.CheckCapability
}

func (h *AlwaysTrueHost) CheckCapability(n *component.NamedCapability) bool {
	if n.Capability == "write_hello" {
		return true
	}
	return false
}

func (h *AlwaysTrueHost) CapabilityFunc(name string) interface{} {
	if name == "write_hello" {
		return h.WriteHelloCap
	}
	return errors.New("Invalid capability requested")
}

func (h *AlwaysTrueHost) WriteHelloCap(ui terminal.UI) error {
	return cap.WriteHello(ui)
}

func (h *AlwaysTrueHost) WriteHelloCapNoUI() error {
	return cap.WriteHelloNoUI()
}

var (
	_ component.Host = (*AlwaysTrueHost)(nil)
)
