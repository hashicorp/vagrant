package host

import (
	"github.com/hashicorp/vagrant-plugin-sdk/component"
	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant/builtin/myplugin/host/cap"
)

type HostConfig struct {
}

// TestOSXHost is a Host implementation for myplugin.
type OSXHost struct {
	config HostConfig

	// Include capability host
	sdkcore.CapabilityHost
}

// DetectFunc implements component.Host
func (h *OSXHost) DetectFunc() interface{} {
	return h.Detect()
}

func (h *OSXHost) Detect() bool {
	return true
}

func (h *OSXHost) InitializeCapabilities() {
	h.RegisterCapability("write_hello", cap.WriteHello)
}

var (
	_ component.Host = (*OSXHost)(nil)
	_ sdkcore.Host   = (*OSXHost)(nil)
)
