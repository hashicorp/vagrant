package host

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/builtin/myplugin/host/cap"
)

type HostConfig struct {
}

// AlwaysTrueHost is a Host implementation for myplugin.
type AlwaysTrueHost struct {
	config HostConfig

	sdkcore.CapabilityHost
}

// DetectFunc implements component.Host
func (h *AlwaysTrueHost) DetectFunc() interface{} {
	return h.Detect
}

func (h *AlwaysTrueHost) Detect() bool {
	h.InitializeCapabilities()
	return true
}

func (h *AlwaysTrueHost) InitializeCapabilities() (err error) {
	err = h.RegisterCapability("write_hello", cap.WriteHelloFunc())
	return
}

var (
	_ component.Host = (*AlwaysTrueHost)(nil)
	_ sdkcore.Host   = (*AlwaysTrueHost)(nil)
)
