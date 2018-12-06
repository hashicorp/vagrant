package vagrant

import (
	"testing"
)

func TestNoGuestCapabilities(t *testing.T) {
	g := NoGuestCapabilities{}
	caps, err := g.GuestCapabilities()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if len(caps) != 0 {
		t.Fatalf("guest capabilities should be empty")
	}
}

func TestNoGuestCapability(t *testing.T) {
	g := NoGuestCapabilities{}
	m := &Machine{}
	cap := &SystemCapability{"Test", "Test"}
	r, err := g.GuestCapability(cap, "args", m)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if r != nil {
		t.Fatalf("capability returned unexpected result")
	}
}

func TestNoHostCapabilities(t *testing.T) {
	h := NoHostCapabilities{}
	caps, err := h.HostCapabilities()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if len(caps) != 0 {
		t.Fatalf("host capabilities should be empty")
	}
}

func TestNoHostCapability(t *testing.T) {
	h := NoHostCapabilities{}
	e := &Environment{}
	cap := &SystemCapability{"Test", "Test"}
	r, err := h.HostCapability(cap, "args", e)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if r != nil {
		t.Fatalf("capability returned unexpected result")
	}
}

func TestNoProviderCapabilities(t *testing.T) {
	p := NoProviderCapabilities{}
	caps, err := p.ProviderCapabilities()
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if len(caps) != 0 {
		t.Fatalf("provider capabilities should be empty")
	}
}

func TestNoProviderCapability(t *testing.T) {
	p := NoProviderCapabilities{}
	m := &Machine{}
	cap := &ProviderCapability{"Test", "Test"}
	r, err := p.ProviderCapability(cap, "args", m)
	if err != nil {
		t.Fatalf("unexpected error: %s", err)
	}
	if r != nil {
		t.Fatalf("capability returned unexpected result")
	}
}
