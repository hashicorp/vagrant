package plugin

import (
	"context"
	"encoding/json"
	"errors"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_common"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_folder"
)

type SyncedFolder interface {
	vagrant.SyncedFolder
	Meta
}

type SyncedFolderPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl SyncedFolder
}

type GRPCSyncedFolderClient struct {
	GRPCCoreClient
	GRPCGuestCapabilitiesClient
	GRPCHostCapabilitiesClient
	GRPCIOClient
	client vagrant_folder.SyncedFolderClient
}

func (c *GRPCSyncedFolderClient) Cleanup(m *vagrant.Machine, o vagrant.FolderOptions) (err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	opts, err := json.Marshal(o)
	if err != nil {
		return
	}
	resp, err := c.client.Cleanup(context.Background(), &vagrant_folder.CleanupRequest{
		Machine: machine,
		Options: string(opts)})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCSyncedFolderClient) Disable(m *vagrant.Machine, f vagrant.FolderList, o vagrant.FolderOptions) (err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	folders, err := json.Marshal(f)
	if err != nil {
		return
	}
	opts, err := json.Marshal(o)
	if err != nil {
		return
	}
	resp, err := c.client.Disable(context.Background(), &vagrant_folder.Request{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCSyncedFolderClient) Enable(m *vagrant.Machine, f vagrant.FolderList, o vagrant.FolderOptions) (err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	folders, err := json.Marshal(f)
	if err != nil {
		return
	}
	opts, err := json.Marshal(o)
	if err != nil {
		return
	}
	resp, err := c.client.Enable(context.Background(), &vagrant_folder.Request{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCSyncedFolderClient) Info() *vagrant.SyncedFolderInfo {
	resp, err := c.client.Info(context.Background(), &vagrant_common.NullRequest{})
	if err != nil {
		return &vagrant.SyncedFolderInfo{}
	}
	return &vagrant.SyncedFolderInfo{
		Description: resp.Description,
		Priority:    resp.Priority}
}

func (c *GRPCSyncedFolderClient) IsUsable(m *vagrant.Machine) (u bool, err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	resp, err := c.client.IsUsable(context.Background(), &vagrant_common.EmptyRequest{
		Machine: machine})
	u = resp.Result
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

func (c *GRPCSyncedFolderClient) Name() string {
	resp, err := c.client.Name(context.Background(), &vagrant_common.NullRequest{})
	if err != nil {
		return ""
	}
	return resp.Name
}

func (c *GRPCSyncedFolderClient) Prepare(m *vagrant.Machine, f vagrant.FolderList, o vagrant.FolderOptions) (err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	folders, err := json.Marshal(f)
	if err != nil {
		return
	}
	opts, err := json.Marshal(o)
	if err != nil {
		return
	}
	resp, err := c.client.Prepare(context.Background(), &vagrant_folder.Request{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	return
}

type GRPCSyncedFolderServer struct {
	GRPCGuestCapabilitiesServer
	GRPCHostCapabilitiesServer
	GRPCIOServer
	Impl SyncedFolder
}

func (s *GRPCSyncedFolderServer) Cleanup(ctx context.Context, req *vagrant_folder.CleanupRequest) (resp *vagrant_common.EmptyResponse, err error) {
	resp = &vagrant_common.EmptyResponse{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	var options vagrant.FolderOptions
	err = json.Unmarshal([]byte(req.Options), &options)
	if err != nil {
		return
	}
	e := s.Impl.Cleanup(machine, options)
	if e != nil {
		resp.Error = e.Error()
	}
	return
}

func (s *GRPCSyncedFolderServer) Disable(ctx context.Context, req *vagrant_folder.Request) (resp *vagrant_common.EmptyResponse, err error) {
	resp = &vagrant_common.EmptyResponse{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	var folders vagrant.FolderList
	err = json.Unmarshal([]byte(req.Folders), &folders)
	if err != nil {
		return
	}
	var options vagrant.FolderOptions
	err = json.Unmarshal([]byte(req.Options), &options)
	if err != nil {
		return
	}
	e := s.Impl.Disable(machine, folders, options)
	if e != nil {
		resp.Error = e.Error()
	}
	return
}

func (s *GRPCSyncedFolderServer) Enable(ctx context.Context, req *vagrant_folder.Request) (resp *vagrant_common.EmptyResponse, err error) {
	resp = &vagrant_common.EmptyResponse{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	var folders vagrant.FolderList
	err = json.Unmarshal([]byte(req.Folders), &folders)
	if err != nil {
		return
	}
	var options vagrant.FolderOptions
	err = json.Unmarshal([]byte(req.Options), &options)
	if err != nil {
		return
	}
	e := s.Impl.Enable(machine, folders, options)
	if e != nil {
		resp.Error = e.Error()
	}
	return
}

func (s *GRPCSyncedFolderServer) Info(ctx context.Context, req *vagrant_common.NullRequest) (*vagrant_folder.InfoResponse, error) {
	r := s.Impl.Info()
	return &vagrant_folder.InfoResponse{
		Description: r.Description,
		Priority:    r.Priority}, nil
}

func (s *GRPCSyncedFolderServer) IsUsable(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.IsResponse, err error) {
	resp = &vagrant_common.IsResponse{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	r, e := s.Impl.IsUsable(machine)
	if e != nil {
		resp.Error = e.Error()
	}
	resp.Result = r
	return
}

func (s *GRPCSyncedFolderServer) Name(ctx context.Context, req *vagrant_common.NullRequest) (*vagrant_common.NameResponse, error) {
	return &vagrant_common.NameResponse{Name: s.Impl.Name()}, nil
}

func (s *GRPCSyncedFolderServer) Prepare(ctx context.Context, req *vagrant_folder.Request) (resp *vagrant_common.EmptyResponse, err error) {
	resp = &vagrant_common.EmptyResponse{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	var folders vagrant.FolderList
	err = json.Unmarshal([]byte(req.Folders), &folders)
	if err != nil {
		return
	}
	var options vagrant.FolderOptions
	err = json.Unmarshal([]byte(req.Options), &options)
	if err != nil {
		return
	}
	e := s.Impl.Prepare(machine, folders, options)
	if e != nil {
		resp.Error = e.Error()
	}
	return
}

func (f *SyncedFolderPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	f.Impl.Init()
	vagrant_folder.RegisterSyncedFolderServer(s,
		&GRPCSyncedFolderServer{
			Impl: f.Impl,
			GRPCIOServer: GRPCIOServer{
				Impl: f.Impl},
			GRPCGuestCapabilitiesServer: GRPCGuestCapabilitiesServer{
				Impl: f.Impl},
			GRPCHostCapabilitiesServer: GRPCHostCapabilitiesServer{
				Impl: f.Impl}})
	return nil
}

func (f *SyncedFolderPlugin) GRPCClient(ctx context.Context, broker *go_plugin.GRPCBroker, c *grpc.ClientConn) (interface{}, error) {
	client := vagrant_folder.NewSyncedFolderClient(c)
	return &GRPCSyncedFolderClient{
		GRPCIOClient: GRPCIOClient{
			client: client},
		GRPCGuestCapabilitiesClient: GRPCGuestCapabilitiesClient{
			client: client},
		GRPCHostCapabilitiesClient: GRPCHostCapabilitiesClient{
			client: client},
		client: client}, nil
}
