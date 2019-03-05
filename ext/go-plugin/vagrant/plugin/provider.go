package plugin

import (
	"context"
	"encoding/json"
	"errors"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_common"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_provider"
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
	client vagrant_provider.ProviderClient
}

func (c *GRPCProviderClient) Action(actionName string, m *vagrant.Machine) (r []string, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.Action(context.Background(), &vagrant_provider.ActionRequest{
		Name:    actionName,
		Machine: machData})
	if err != nil {
		return
	}
	r = resp.Result
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCProviderClient) Info() *vagrant.ProviderInfo {
	resp, err := c.client.Info(context.Background(), &vagrant_common.NullRequest{})
	if err != nil {
		return &vagrant.ProviderInfo{}
	}
	return &vagrant.ProviderInfo{
		Description: resp.Description,
		Priority:    resp.Priority}
}

func (c *GRPCProviderClient) IsInstalled(m *vagrant.Machine) (r bool, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.IsInstalled(context.Background(), &vagrant_common.EmptyRequest{
		Machine: machData})
	if err != nil {
		return
	}
	r = resp.Result
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCProviderClient) IsUsable(m *vagrant.Machine) (r bool, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.IsUsable(context.Background(), &vagrant_common.EmptyRequest{
		Machine: machData})
	if err != nil {
		return
	}
	r = resp.Result
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCProviderClient) MachineIdChanged(m *vagrant.Machine) (err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.MachineIdChanged(context.Background(), &vagrant_common.EmptyRequest{
		Machine: machData})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCProviderClient) RunAction(actName string, args interface{}, m *vagrant.Machine) (r interface{}, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	runData, err := json.Marshal(args)
	if err != nil {
		return
	}
	resp, err := c.client.RunAction(context.Background(), &vagrant_provider.RunActionRequest{
		Name:    actName,
		Data:    string(runData),
		Machine: machData})
	if err != nil {
		return
	}
	err = json.Unmarshal([]byte(resp.Data), &r)
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCProviderClient) SshInfo(m *vagrant.Machine) (r *vagrant.SshInfo, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.SshInfo(context.Background(), &vagrant_common.EmptyRequest{
		Machine: machData})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	r = &vagrant.SshInfo{
		Host:           resp.Host,
		Port:           resp.Port,
		PrivateKeyPath: resp.PrivateKeyPath,
		Username:       resp.Username}
	return
}

func (c *GRPCProviderClient) State(m *vagrant.Machine) (r *vagrant.MachineState, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.State(context.Background(), &vagrant_common.EmptyRequest{
		Machine: machData})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	r = &vagrant.MachineState{
		Id:        resp.Id,
		ShortDesc: resp.ShortDescription,
		LongDesc:  resp.LongDescription}
	return
}

func (c *GRPCProviderClient) Name() string {
	resp, err := c.client.Name(context.Background(), &vagrant_common.NullRequest{})
	if err != nil {
		return ""
	}
	return resp.Name
}

func (p *ProviderPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_provider.NewProviderClient(c)
	return &GRPCProviderClient{
		GRPCConfigClient: GRPCConfigClient{
			client: client},
		GRPCGuestCapabilitiesClient: GRPCGuestCapabilitiesClient{
			client: client},
		GRPCHostCapabilitiesClient: GRPCHostCapabilitiesClient{
			client: client},
		GRPCProviderCapabilitiesClient: GRPCProviderCapabilitiesClient{
			client: client},
		GRPCIOClient: GRPCIOClient{
			client: client},
		client: client,
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
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	r, e := s.Impl.Action(req.Name, m)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	resp.Result = r
	return
}

func (s *GRPCProviderServer) RunAction(ctx context.Context, req *vagrant_provider.RunActionRequest) (resp *vagrant_provider.RunActionResponse, err error) {
	resp = &vagrant_provider.RunActionResponse{}
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	var args interface{}
	err = json.Unmarshal([]byte(req.Data), &args)
	if err != nil {
		return
	}
	r, e := s.Impl.RunAction(req.Name, args, m)
	if e != nil {
		resp.Error = e.Error()
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
	r := s.Impl.Info()
	return &vagrant_provider.InfoResponse{
		Description: r.Description,
		Priority:    r.Priority}, nil
}

func (s *GRPCProviderServer) IsInstalled(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.IsResponse, err error) {
	resp = &vagrant_common.IsResponse{}
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	r, e := s.Impl.IsInstalled(m)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	resp.Result = r
	return
}

func (s *GRPCProviderServer) IsUsable(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.IsResponse, err error) {
	resp = &vagrant_common.IsResponse{}
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	r, e := s.Impl.IsUsable(m)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	resp.Result = r
	return
}

func (s *GRPCProviderServer) SshInfo(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_provider.SshInfoResponse, err error) {
	resp = &vagrant_provider.SshInfoResponse{}
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	r, e := s.Impl.SshInfo(m)
	if e != nil {
		resp.Error = e.Error()
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
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	r, e := s.Impl.State(m)
	if e != nil {
		resp.Error = e.Error()
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
	m, e := vagrant.LoadMachine(req.Machine, s.Impl)
	if e != nil {
		resp.Error = e.Error()
		return
	}
	e = s.Impl.MachineIdChanged(m)
	if e != nil {
		resp.Error = e.Error()
	}
	return
}

func (s *GRPCProviderServer) Name(ctx context.Context, req *vagrant_common.NullRequest) (*vagrant_common.NameResponse, error) {
	return &vagrant_common.NameResponse{Name: s.Impl.Name()}, nil
}
