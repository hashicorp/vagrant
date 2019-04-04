package plugin

import (
	"context"
	"encoding/json"

	"golang.org/x/sync/errgroup"
	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto"

	"github.com/LK4D4/joincontext"
)

type GuestCapabilities interface {
	vagrant.GuestCapabilities
	Meta
}

type GuestCapabilitiesPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl GuestCapabilities
}

func (g *GuestCapabilitiesPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	g.Impl.Init()
	vagrant_proto.RegisterGuestCapabilitiesServer(s, &GRPCGuestCapabilitiesServer{
		Impl: g.Impl,
		GRPCIOServer: GRPCIOServer{
			Impl: g.Impl}})
	return nil
}

func (g *GuestCapabilitiesPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_proto.NewGuestCapabilitiesClient(c)
	return &GRPCGuestCapabilitiesClient{
		client:  client,
		doneCtx: ctx,
		GRPCIOClient: GRPCIOClient{
			client:  client,
			doneCtx: ctx}}, nil
}

type GRPCGuestCapabilitiesServer struct {
	GRPCIOServer
	Impl GuestCapabilities
}

func (s *GRPCGuestCapabilitiesServer) GuestCapabilities(ctx context.Context, req *vagrant_proto.Empty) (resp *vagrant_proto.SystemCapabilityList, err error) {
	resp = &vagrant_proto.SystemCapabilityList{}
	g, _ := errgroup.WithContext(ctx)
	g.Go(func() (err error) {
		r, err := s.Impl.GuestCapabilities()
		if err != nil {
			return
		}
		for _, cap := range r {
			rcap := &vagrant_proto.SystemCapability{Name: cap.Name, Platform: cap.Platform}
			resp.Capabilities = append(resp.Capabilities, rcap)
		}
		return
	})
	err = g.Wait()
	return
}

func (s *GRPCGuestCapabilitiesServer) GuestCapability(ctx context.Context, req *vagrant_proto.GuestCapabilityRequest) (resp *vagrant_proto.GenericResponse, err error) {
	resp = &vagrant_proto.GenericResponse{}
	g, gctx := errgroup.WithContext(ctx)
	g.Go(func() (err error) {
		var args interface{}
		if err = json.Unmarshal([]byte(req.Arguments), &args); err != nil {
			return
		}
		machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		cap := &vagrant.SystemCapability{
			Name:     req.Capability.Name,
			Platform: req.Capability.Platform}
		r, err := s.Impl.GuestCapability(gctx, cap, args, machine)
		result, err := json.Marshal(r)
		if err != nil {
			return
		}
		resp.Result = string(result)
		return
	})
	err = g.Wait()
	return
}

type GRPCGuestCapabilitiesClient struct {
	GRPCCoreClient
	GRPCIOClient
	client  vagrant_proto.GuestCapabilitiesClient
	doneCtx context.Context
}

func (c *GRPCGuestCapabilitiesClient) GuestCapabilities() (caps []vagrant.SystemCapability, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.GuestCapabilities(jctx, &vagrant_proto.Empty{})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	caps = make([]vagrant.SystemCapability, len(resp.Capabilities))
	for i := 0; i < len(resp.Capabilities); i++ {
		cap := vagrant.SystemCapability{
			Name:     resp.Capabilities[i].Name,
			Platform: resp.Capabilities[i].Platform}
		caps[i] = cap
	}
	return
}

func (c *GRPCGuestCapabilitiesClient) GuestCapability(ctx context.Context, cap *vagrant.SystemCapability, args interface{}, machine *vagrant.Machine) (result interface{}, err error) {
	a, err := json.Marshal(args)
	if err != nil {
		return
	}
	m, err := vagrant.DumpMachine(machine)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.GuestCapability(jctx, &vagrant_proto.GuestCapabilityRequest{
		Capability: &vagrant_proto.SystemCapability{Name: cap.Name, Platform: cap.Platform},
		Machine:    m,
		Arguments:  string(a)})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	err = json.Unmarshal([]byte(resp.Result), &result)
	return
}

type HostCapabilities interface {
	vagrant.HostCapabilities
	Meta
}

type HostCapabilitiesPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl HostCapabilities
}

func (h *HostCapabilitiesPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	h.Impl.Init()
	vagrant_proto.RegisterHostCapabilitiesServer(s, &GRPCHostCapabilitiesServer{
		Impl: h.Impl,
		GRPCIOServer: GRPCIOServer{
			Impl: h.Impl}})
	return nil
}

func (h *HostCapabilitiesPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_proto.NewHostCapabilitiesClient(c)
	return &GRPCHostCapabilitiesClient{
		client:  client,
		doneCtx: ctx,
		GRPCIOClient: GRPCIOClient{
			client:  client,
			doneCtx: ctx}}, nil
}

type GRPCHostCapabilitiesServer struct {
	GRPCIOServer
	Impl HostCapabilities
}

func (s *GRPCHostCapabilitiesServer) HostCapabilities(ctx context.Context, req *vagrant_proto.Empty) (resp *vagrant_proto.SystemCapabilityList, err error) {
	resp = &vagrant_proto.SystemCapabilityList{}
	g, _ := errgroup.WithContext(ctx)
	g.Go(func() (err error) {
		r, err := s.Impl.HostCapabilities()
		if err != nil {
			return
		}
		for _, cap := range r {
			rcap := &vagrant_proto.SystemCapability{Name: cap.Name, Platform: cap.Platform}
			resp.Capabilities = append(resp.Capabilities, rcap)
		}
		return
	})
	err = g.Wait()
	return
}

func (s *GRPCHostCapabilitiesServer) HostCapability(ctx context.Context, req *vagrant_proto.HostCapabilityRequest) (resp *vagrant_proto.GenericResponse, err error) {
	resp = &vagrant_proto.GenericResponse{}
	g, gctx := errgroup.WithContext(ctx)
	g.Go(func() (err error) {
		var args interface{}
		if err = json.Unmarshal([]byte(req.Arguments), &args); err != nil {
			return
		}
		env, err := vagrant.LoadEnvironment(req.Environment, s.Impl)
		if err != nil {
			return
		}
		cap := &vagrant.SystemCapability{
			Name:     req.Capability.Name,
			Platform: req.Capability.Platform}

		r, err := s.Impl.HostCapability(gctx, cap, args, env)
		result, err := json.Marshal(r)
		if err != nil {
			return
		}
		resp.Result = string(result)
		return
	})
	err = g.Wait()
	return
}

type GRPCHostCapabilitiesClient struct {
	GRPCCoreClient
	GRPCIOClient
	client  vagrant_proto.HostCapabilitiesClient
	doneCtx context.Context
}

func (c *GRPCHostCapabilitiesClient) HostCapabilities() (caps []vagrant.SystemCapability, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.HostCapabilities(jctx, &vagrant_proto.Empty{})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	caps = make([]vagrant.SystemCapability, len(resp.Capabilities))
	for i := 0; i < len(resp.Capabilities); i++ {
		cap := vagrant.SystemCapability{
			Name:     resp.Capabilities[i].Name,
			Platform: resp.Capabilities[i].Platform}
		caps[i] = cap
	}
	return
}

func (c *GRPCHostCapabilitiesClient) HostCapability(ctx context.Context, cap *vagrant.SystemCapability, args interface{}, env *vagrant.Environment) (result interface{}, err error) {
	a, err := json.Marshal(args)
	if err != nil {
		return
	}
	e, err := vagrant.DumpEnvironment(env)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.HostCapability(jctx, &vagrant_proto.HostCapabilityRequest{
		Capability: &vagrant_proto.SystemCapability{
			Name:     cap.Name,
			Platform: cap.Platform},
		Environment: e,
		Arguments:   string(a)})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	err = json.Unmarshal([]byte(resp.Result), &result)
	return
}

type ProviderCapabilities interface {
	vagrant.ProviderCapabilities
	Meta
}

type ProviderCapabilitiesPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl ProviderCapabilities
}

func (p *ProviderCapabilitiesPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	p.Impl.Init()
	vagrant_proto.RegisterProviderCapabilitiesServer(s, &GRPCProviderCapabilitiesServer{
		Impl: p.Impl,
		GRPCIOServer: GRPCIOServer{
			Impl: p.Impl}})
	return nil
}

func (p *ProviderCapabilitiesPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_proto.NewProviderCapabilitiesClient(c)
	return &GRPCProviderCapabilitiesClient{
		client:  client,
		doneCtx: ctx,
		GRPCIOClient: GRPCIOClient{
			client:  client,
			doneCtx: ctx}}, nil
}

type GRPCProviderCapabilitiesServer struct {
	GRPCIOServer
	Impl ProviderCapabilities
}

func (s *GRPCProviderCapabilitiesServer) ProviderCapabilities(ctx context.Context, req *vagrant_proto.Empty) (resp *vagrant_proto.ProviderCapabilityList, err error) {
	resp = &vagrant_proto.ProviderCapabilityList{}
	g, _ := errgroup.WithContext(ctx)
	g.Go(func() (err error) {
		r, err := s.Impl.ProviderCapabilities()
		if err != nil {
			return
		}
		for _, cap := range r {
			rcap := &vagrant_proto.ProviderCapability{Name: cap.Name, Provider: cap.Provider}
			resp.Capabilities = append(resp.Capabilities, rcap)
		}
		return
	})
	err = g.Wait()
	return
}

func (s *GRPCProviderCapabilitiesServer) ProviderCapability(ctx context.Context, req *vagrant_proto.ProviderCapabilityRequest) (resp *vagrant_proto.GenericResponse, err error) {
	resp = &vagrant_proto.GenericResponse{}
	g, gctx := errgroup.WithContext(ctx)
	g.Go(func() (err error) {
		var args interface{}
		if err = json.Unmarshal([]byte(req.Arguments), &args); err != nil {
			return
		}
		m, err := vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		cap := &vagrant.ProviderCapability{
			Name:     req.Capability.Name,
			Provider: req.Capability.Provider}

		r, err := s.Impl.ProviderCapability(gctx, cap, args, m)
		if err != nil {
			return
		}
		result, err := json.Marshal(r)
		if err != nil {
			return
		}
		resp.Result = string(result)
		return
	})
	err = g.Wait()
	return
}

type GRPCProviderCapabilitiesClient struct {
	GRPCCoreClient
	GRPCIOClient
	client  vagrant_proto.ProviderCapabilitiesClient
	doneCtx context.Context
}

func (c *GRPCProviderCapabilitiesClient) ProviderCapabilities() (caps []vagrant.ProviderCapability, err error) {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.ProviderCapabilities(jctx, &vagrant_proto.Empty{})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	caps = make([]vagrant.ProviderCapability, len(resp.Capabilities))
	for i := 0; i < len(resp.Capabilities); i++ {
		cap := vagrant.ProviderCapability{
			Name:     resp.Capabilities[i].Name,
			Provider: resp.Capabilities[i].Provider}
		caps[i] = cap
	}
	return
}

func (c *GRPCProviderCapabilitiesClient) ProviderCapability(ctx context.Context, cap *vagrant.ProviderCapability, args interface{}, machine *vagrant.Machine) (result interface{}, err error) {
	a, err := json.Marshal(args)
	if err != nil {
		return
	}
	m, err := vagrant.DumpMachine(machine)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.ProviderCapability(jctx, &vagrant_proto.ProviderCapabilityRequest{
		Capability: &vagrant_proto.ProviderCapability{
			Name:     cap.Name,
			Provider: cap.Provider},
		Machine:   m,
		Arguments: string(a)})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	err = json.Unmarshal([]byte(resp.Result), &result)
	return
}
