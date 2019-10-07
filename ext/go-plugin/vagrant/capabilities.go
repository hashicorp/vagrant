package vagrant

import (
	"context"
)

type SystemCapability struct {
	Name     string `json:"name"`
	Platform string `json:"platform"`
}

type ProviderCapability struct {
	Name     string `json:"name"`
	Provider string `json:"provider"`
}

type GuestCapabilities interface {
	GuestCapabilities() (caps []SystemCapability, err error)
	GuestCapability(ctx context.Context, cap *SystemCapability, args interface{}, machine *Machine) (result interface{}, err error)
}

type HostCapabilities interface {
	HostCapabilities() (caps []SystemCapability, err error)
	HostCapability(ctx context.Context, cap *SystemCapability, args interface{}, env *Environment) (result interface{}, err error)
}

type ProviderCapabilities interface {
	ProviderCapabilities() (caps []ProviderCapability, err error)
	ProviderCapability(ctx context.Context, cap *ProviderCapability, args interface{}, machine *Machine) (result interface{}, err error)
}

type NoGuestCapabilities struct{}
type NoHostCapabilities struct{}
type NoProviderCapabilities struct{}

func (g *NoGuestCapabilities) GuestCapabilities() (caps []SystemCapability, err error) {
	caps = make([]SystemCapability, 0)
	return
}

func (g *NoGuestCapabilities) GuestCapability(x context.Context, c *SystemCapability, a interface{}, m *Machine) (r interface{}, err error) {
	return
}

func (h *NoHostCapabilities) HostCapabilities() (caps []SystemCapability, err error) {
	caps = make([]SystemCapability, 0)
	return
}

func (h *NoHostCapabilities) HostCapability(x context.Context, c *SystemCapability, a interface{}, e *Environment) (r interface{}, err error) {
	return
}

func (p *NoProviderCapabilities) ProviderCapabilities() (caps []ProviderCapability, err error) {
	caps = make([]ProviderCapability, 0)
	return
}

func (p *NoProviderCapabilities) ProviderCapability(x context.Context, cap *ProviderCapability, args interface{}, machine *Machine) (result interface{}, err error) {
	return
}
