package plugin

import (
	"context"
	"encoding/json"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto"

	"github.com/LK4D4/joincontext"
)

type Provider interface {
	vagrant.Provider
	Meta
}

type ProviderPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl Provider
}

type GRPCProviderClient struct {
	GRPCCoreClient
	GRPCConfigClient
	GRPCGuestCapabilitiesClient
	GRPCHostCapabilitiesClient
	GRPCProviderCapabilitiesClient
	GRPCIOClient
	client  vagrant_proto.ProviderClient
	doneCtx context.Context
}

func (c *GRPCProviderClient) Action(ctx context.Context, actionName string, m *vagrant.Machine) (r []string, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}

	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Action(jctx, &vagrant_proto.GenericAction{
		Name:    actionName,
		Machine: machData})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	r = resp.Items
	return
}

func (c *GRPCProviderClient) Info() *vagrant.ProviderInfo {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Info(jctx, &vagrant_proto.Empty{})
	if err != nil {
		return &vagrant.ProviderInfo{}
	}
	return &vagrant.ProviderInfo{
		Description: resp.Description,
		Priority:    resp.Priority}
}

func (c *GRPCProviderClient) IsInstalled(ctx context.Context, m *vagrant.Machine) (r bool, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.IsInstalled(jctx, &vagrant_proto.Machine{
		Machine: machData})
	if err != nil {
		return false, handleGrpcError(err, c.doneCtx, ctx)
	}
	r = resp.Result
	return
}

func (c *GRPCProviderClient) IsUsable(ctx context.Context, m *vagrant.Machine) (r bool, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.IsUsable(jctx, &vagrant_proto.Machine{
		Machine: machData})
	if err != nil {
		return false, handleGrpcError(err, c.doneCtx, ctx)
	}
	r = resp.Result
	return
}

func (c *GRPCProviderClient) MachineIdChanged(ctx context.Context, m *vagrant.Machine) (err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	_, err = c.client.MachineIdChanged(jctx, &vagrant_proto.Machine{
		Machine: machData})
	if err != nil {
		return handleGrpcError(err, c.doneCtx, ctx)
	}
	return
}

func (c *GRPCProviderClient) RunAction(ctx context.Context, actName string, args interface{}, m *vagrant.Machine) (r interface{}, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	runData, err := json.Marshal(args)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.RunAction(jctx, &vagrant_proto.ExecuteAction{
		Name:    actName,
		Data:    string(runData),
		Machine: machData})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	err = json.Unmarshal([]byte(resp.Result), &r)
	if err != nil {
		return
	}
	return
}

func (c *GRPCProviderClient) SshInfo(ctx context.Context, m *vagrant.Machine) (r *vagrant.SshInfo, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.SshInfo(jctx, &vagrant_proto.Machine{
		Machine: machData})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	r = &vagrant.SshInfo{
		Host:           resp.Host,
		Port:           resp.Port,
		PrivateKeyPath: resp.PrivateKeyPath,
		Username:       resp.Username}
	return
}

func (c *GRPCProviderClient) State(ctx context.Context, m *vagrant.Machine) (r *vagrant.MachineState, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.State(jctx, &vagrant_proto.Machine{
		Machine: machData})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	r = &vagrant.MachineState{
		Id:        resp.Id,
		ShortDesc: resp.ShortDescription,
		LongDesc:  resp.LongDescription}
	return
}

func (c *GRPCProviderClient) Name() string {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Name(jctx, &vagrant_proto.Empty{})
	if err != nil {
		return ""
	}
	return resp.Name
}

func (p *ProviderPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_proto.NewProviderClient(c)
	return &GRPCProviderClient{
		GRPCConfigClient: GRPCConfigClient{
			client:  client,
			doneCtx: ctx},
		GRPCGuestCapabilitiesClient: GRPCGuestCapabilitiesClient{
			client:  client,
			doneCtx: ctx},
		GRPCHostCapabilitiesClient: GRPCHostCapabilitiesClient{
			client:  client,
			doneCtx: ctx},
		GRPCProviderCapabilitiesClient: GRPCProviderCapabilitiesClient{
			client:  client,
			doneCtx: ctx},
		GRPCIOClient: GRPCIOClient{
			client:  client,
			doneCtx: ctx},
		client:  client,
		doneCtx: ctx,
	}, nil
}

func (p *ProviderPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	p.Impl.Init()
	vagrant_proto.RegisterProviderServer(s, &GRPCProviderServer{
		Impl: p.Impl,
		GRPCConfigServer: GRPCConfigServer{
			Impl: p.Impl},
		GRPCGuestCapabilitiesServer: GRPCGuestCapabilitiesServer{
			Impl: p.Impl},
		GRPCHostCapabilitiesServer: GRPCHostCapabilitiesServer{
			Impl: p.Impl},
		GRPCProviderCapabilitiesServer: GRPCProviderCapabilitiesServer{
			Impl: p.Impl},
		GRPCIOServer: GRPCIOServer{
			Impl: p.Impl}})
	return nil
}

type GRPCProviderServer struct {
	GRPCIOServer
	GRPCConfigServer
	GRPCGuestCapabilitiesServer
	GRPCHostCapabilitiesServer
	GRPCProviderCapabilitiesServer
	Impl Provider
}

func (s *GRPCProviderServer) Action(ctx context.Context, req *vagrant_proto.GenericAction) (resp *vagrant_proto.ListResponse, err error) {
	var (
		r []string
		m *vagrant.Machine
	)
	resp = &vagrant_proto.ListResponse{}
	n := make(chan struct{})
	go func() {
		defer func() { n <- struct{}{} }()
		m, err = vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		r, err = s.Impl.Action(ctx, req.Name, m)
		resp.Items = r
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) RunAction(ctx context.Context, req *vagrant_proto.ExecuteAction) (resp *vagrant_proto.GenericResponse, err error) {
	var (
		args, r interface{}
		m       *vagrant.Machine
	)
	resp = &vagrant_proto.GenericResponse{}
	n := make(chan struct{})
	go func() {
		defer func() { n <- struct{}{} }()
		m, err = vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		err = json.Unmarshal([]byte(req.Data), &args)
		if err != nil {
			return
		}
		r, err = s.Impl.RunAction(ctx, req.Name, args, m)
		if err != nil {
			return
		}
		result, err := json.Marshal(r)
		if err != nil {
			return
		}
		resp.Result = string(result)
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) Info(ctx context.Context, req *vagrant_proto.Empty) (*vagrant_proto.PluginInfo, error) {
	resp := &vagrant_proto.PluginInfo{}
	var r *vagrant.ProviderInfo
	n := make(chan struct{})
	go func() {
		r = s.Impl.Info()
		resp.Description = r.Description
		resp.Priority = r.Priority
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return nil, nil
	case <-n:
	}
	return resp, nil
}

func (s *GRPCProviderServer) IsInstalled(ctx context.Context, req *vagrant_proto.Machine) (resp *vagrant_proto.Valid, err error) {
	var m *vagrant.Machine
	resp = &vagrant_proto.Valid{}
	n := make(chan struct{})
	go func() {
		defer func() { n <- struct{}{} }()
		m, err = vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		resp.Result, err = s.Impl.IsInstalled(ctx, m)
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) IsUsable(ctx context.Context, req *vagrant_proto.Machine) (resp *vagrant_proto.Valid, err error) {
	var m *vagrant.Machine
	resp = &vagrant_proto.Valid{}
	n := make(chan struct{})
	go func() {
		defer func() { n <- struct{}{} }()
		m, err = vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		resp.Result, err = s.Impl.IsUsable(ctx, m)
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) SshInfo(ctx context.Context, req *vagrant_proto.Machine) (resp *vagrant_proto.MachineSshInfo, err error) {
	resp = &vagrant_proto.MachineSshInfo{}
	var r *vagrant.SshInfo
	var m *vagrant.Machine
	n := make(chan struct{})
	go func() {
		defer func() { n <- struct{}{} }()
		m, err = vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		r, err = s.Impl.SshInfo(ctx, m)
		if err != nil {
			return
		}
		resp = &vagrant_proto.MachineSshInfo{
			Host:           r.Host,
			Port:           r.Port,
			Username:       r.Username,
			PrivateKeyPath: r.PrivateKeyPath}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) State(ctx context.Context, req *vagrant_proto.Machine) (resp *vagrant_proto.MachineState, err error) {
	resp = &vagrant_proto.MachineState{}
	var r *vagrant.MachineState
	n := make(chan struct{})
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		defer func() { n <- struct{}{} }()
		r, err = s.Impl.State(ctx, m)
		if err != nil {
			return
		}
		resp = &vagrant_proto.MachineState{
			Id:               r.Id,
			ShortDescription: r.ShortDesc,
			LongDescription:  r.LongDesc}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) MachineIdChanged(ctx context.Context, req *vagrant_proto.Machine) (resp *vagrant_proto.Machine, err error) {
	resp = &vagrant_proto.Machine{}
	var mdata string
	var m *vagrant.Machine
	n := make(chan struct{})
	go func() {
		defer func() { n <- struct{}{} }()
		m, err = vagrant.LoadMachine(req.Machine, s.Impl)
		if err != nil {
			return
		}
		err = s.Impl.MachineIdChanged(ctx, m)
		if err != nil {
			return
		}
		mdata, err = vagrant.DumpMachine(m)
		if err != nil {
			return
		}
		resp = &vagrant_proto.Machine{Machine: mdata}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) Name(ctx context.Context, req *vagrant_proto.Empty) (*vagrant_proto.Identifier, error) {
	return &vagrant_proto.Identifier{Name: s.Impl.Name()}, nil
}
