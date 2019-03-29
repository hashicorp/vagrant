package plugin

import (
	"context"
	"encoding/json"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_common"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_provider"

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
	client  vagrant_provider.ProviderClient
	doneCtx context.Context
}

func (c *GRPCProviderClient) Action(ctx context.Context, actionName string, m *vagrant.Machine) (r []string, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}

	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Action(jctx, &vagrant_provider.ActionRequest{
		Name:    actionName,
		Machine: machData})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	r = resp.Result
	return
}

func (c *GRPCProviderClient) Info() *vagrant.ProviderInfo {
	ctx := context.Background()
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.Info(jctx, &vagrant_common.NullRequest{})
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
	resp, err := c.client.IsInstalled(jctx, &vagrant_common.EmptyRequest{
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
	resp, err := c.client.IsUsable(jctx, &vagrant_common.EmptyRequest{
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
	_, err = c.client.MachineIdChanged(jctx, &vagrant_common.EmptyRequest{
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
	resp, err := c.client.RunAction(jctx, &vagrant_provider.RunActionRequest{
		Name:    actName,
		Data:    string(runData),
		Machine: machData})
	if err != nil {
		return nil, handleGrpcError(err, c.doneCtx, ctx)
	}
	err = json.Unmarshal([]byte(resp.Data), &r)
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
	resp, err := c.client.SshInfo(jctx, &vagrant_common.EmptyRequest{
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
	resp, err := c.client.State(jctx, &vagrant_common.EmptyRequest{
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
	resp, err := c.client.Name(jctx, &vagrant_common.NullRequest{})
	if err != nil {
		return ""
	}
	return resp.Name
}

func (p *ProviderPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_provider.NewProviderClient(c)
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
	vagrant_provider.RegisterProviderServer(s, &GRPCProviderServer{
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

func (s *GRPCProviderServer) Action(ctx context.Context, req *vagrant_provider.ActionRequest) (resp *vagrant_provider.ActionResponse, err error) {
	resp = &vagrant_provider.ActionResponse{}
	var r []string
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		r, err = s.Impl.Action(ctx, req.Name, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
	}

	if err != nil {
		return
	}
	resp.Result = r
	return
}

func (s *GRPCProviderServer) RunAction(ctx context.Context, req *vagrant_provider.RunActionRequest) (resp *vagrant_provider.RunActionResponse, err error) {
	resp = &vagrant_provider.RunActionResponse{}
	var args, r interface{}
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	err = json.Unmarshal([]byte(req.Data), &args)
	if err != nil {
		return
	}
	go func() {
		r, err = s.Impl.RunAction(ctx, req.Name, args, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
	}

	if err != nil {
		return
	}
	result, err := json.Marshal(r)
	if err != nil {
		return
	}
	resp.Data = string(result)
	return
}

func (s *GRPCProviderServer) Info(ctx context.Context, req *vagrant_common.NullRequest) (*vagrant_provider.InfoResponse, error) {
	var r *vagrant.ProviderInfo
	n := make(chan struct{}, 1)
	go func() {
		r = s.Impl.Info()
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return nil, nil
	case <-n:
	}

	return &vagrant_provider.InfoResponse{
		Description: r.Description,
		Priority:    r.Priority}, nil
}

func (s *GRPCProviderServer) IsInstalled(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.IsResponse, err error) {
	resp = &vagrant_common.IsResponse{}
	var r bool
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		r, err = s.Impl.IsInstalled(ctx, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
	}
	if err != nil {
		return
	}
	resp.Result = r
	return
}

func (s *GRPCProviderServer) IsUsable(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.IsResponse, err error) {
	resp = &vagrant_common.IsResponse{}
	var r bool
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		r, err = s.Impl.IsUsable(ctx, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
	}
	if err != nil {
		return
	}
	resp.Result = r
	return
}

func (s *GRPCProviderServer) SshInfo(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_provider.SshInfoResponse, err error) {
	resp = &vagrant_provider.SshInfoResponse{}
	var r *vagrant.SshInfo
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		r, err = s.Impl.SshInfo(ctx, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
	}

	if err != nil {
		return
	}
	resp = &vagrant_provider.SshInfoResponse{
		Host:           r.Host,
		Port:           r.Port,
		Username:       r.Username,
		PrivateKeyPath: r.PrivateKeyPath}
	return
}

func (s *GRPCProviderServer) State(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_provider.StateResponse, err error) {
	resp = &vagrant_provider.StateResponse{}
	var r *vagrant.MachineState
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		r, err = s.Impl.State(ctx, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return
	case <-n:
	}

	if err != nil {
		return
	}
	resp = &vagrant_provider.StateResponse{
		Id:               r.Id,
		ShortDescription: r.ShortDesc,
		LongDescription:  r.LongDesc}
	return
}

func (s *GRPCProviderServer) MachineIdChanged(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.EmptyResponse, err error) {
	resp = &vagrant_common.EmptyResponse{}
	n := make(chan struct{}, 1)
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	go func() {
		err = s.Impl.MachineIdChanged(ctx, m)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCProviderServer) Name(ctx context.Context, req *vagrant_common.NullRequest) (*vagrant_common.NameResponse, error) {
	return &vagrant_common.NameResponse{Name: s.Impl.Name()}, nil
}
