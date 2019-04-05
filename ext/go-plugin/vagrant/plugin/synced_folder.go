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
	client  vagrant_proto.SyncedFolderClient
	doneCtx context.Context
}

func (c *GRPCSyncedFolderClient) Cleanup(ctx context.Context, m *vagrant.Machine, o vagrant.FolderOptions) (err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	opts, err := json.Marshal(o)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	_, err = c.client.Cleanup(jctx, &vagrant_proto.SyncedFolders{
		Machine: machine,
		Options: string(opts)})
	return handleGrpcError(err, c.doneCtx, ctx)
}

func (c *GRPCSyncedFolderClient) Disable(ctx context.Context, m *vagrant.Machine, f vagrant.FolderList, o vagrant.FolderOptions) (err error) {
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
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	_, err = c.client.Disable(jctx, &vagrant_proto.SyncedFolders{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	return handleGrpcError(err, c.doneCtx, ctx)
}

func (c *GRPCSyncedFolderClient) Enable(ctx context.Context, m *vagrant.Machine, f vagrant.FolderList, o vagrant.FolderOptions) (err error) {
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
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	_, err = c.client.Enable(jctx, &vagrant_proto.SyncedFolders{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	return handleGrpcError(err, c.doneCtx, ctx)
}

func (c *GRPCSyncedFolderClient) Info() *vagrant.SyncedFolderInfo {
	resp, err := c.client.Info(context.Background(), &vagrant_proto.Empty{})
	if err != nil {
		return &vagrant.SyncedFolderInfo{}
	}
	return &vagrant.SyncedFolderInfo{
		Description: resp.Description,
		Priority:    resp.Priority}
}

func (c *GRPCSyncedFolderClient) IsUsable(ctx context.Context, m *vagrant.Machine) (u bool, err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.IsUsable(jctx, &vagrant_proto.Machine{
		Machine: machine})
	if err != nil {
		return false, handleGrpcError(err, c.doneCtx, ctx)
	}
	u = resp.Result
	return
}

func (c *GRPCSyncedFolderClient) Name() string {
	resp, err := c.client.Name(context.Background(), &vagrant_proto.Empty{})
	if err != nil {
		return ""
	}
	return resp.Name
}

func (c *GRPCSyncedFolderClient) Prepare(ctx context.Context, m *vagrant.Machine, f vagrant.FolderList, o vagrant.FolderOptions) (err error) {
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
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	_, err = c.client.Prepare(jctx, &vagrant_proto.SyncedFolders{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	return handleGrpcError(err, c.doneCtx, ctx)
}

type GRPCSyncedFolderServer struct {
	GRPCGuestCapabilitiesServer
	GRPCHostCapabilitiesServer
	GRPCIOServer
	Impl SyncedFolder
}

func (s *GRPCSyncedFolderServer) Cleanup(ctx context.Context, req *vagrant_proto.SyncedFolders) (resp *vagrant_proto.Empty, err error) {
	resp = &vagrant_proto.Empty{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	var options vagrant.FolderOptions
	err = json.Unmarshal([]byte(req.Options), &options)
	if err != nil {
		return
	}
	err = s.Impl.Cleanup(ctx, machine, options)
	return
}

func (s *GRPCSyncedFolderServer) Disable(ctx context.Context, req *vagrant_proto.SyncedFolders) (resp *vagrant_proto.Empty, err error) {
	resp = &vagrant_proto.Empty{}
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
	err = s.Impl.Disable(ctx, machine, folders, options)
	return
}

func (s *GRPCSyncedFolderServer) Enable(ctx context.Context, req *vagrant_proto.SyncedFolders) (resp *vagrant_proto.Empty, err error) {
	resp = &vagrant_proto.Empty{}
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
	err = s.Impl.Enable(ctx, machine, folders, options)
	return
}

func (s *GRPCSyncedFolderServer) Info(ctx context.Context, req *vagrant_proto.Empty) (resp *vagrant_proto.PluginInfo, err error) {
	resp = &vagrant_proto.PluginInfo{}
	r := s.Impl.Info()
	resp.Description = r.Description
	resp.Priority = r.Priority
	return
}

func (s *GRPCSyncedFolderServer) IsUsable(ctx context.Context, req *vagrant_proto.Machine) (resp *vagrant_proto.Valid, err error) {
	resp = &vagrant_proto.Valid{}
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	r, err := s.Impl.IsUsable(ctx, machine)
	if err != nil {
		return
	}
	resp.Result = r
	return
}

func (s *GRPCSyncedFolderServer) Name(_ context.Context, req *vagrant_proto.Empty) (*vagrant_proto.Identifier, error) {
	return &vagrant_proto.Identifier{Name: s.Impl.Name()}, nil
}

func (s *GRPCSyncedFolderServer) Prepare(ctx context.Context, req *vagrant_proto.SyncedFolders) (resp *vagrant_proto.Empty, err error) {
	resp = &vagrant_proto.Empty{}
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
	err = s.Impl.Prepare(ctx, machine, folders, options)
	return
}

func (f *SyncedFolderPlugin) GRPCServer(broker *go_plugin.GRPCBroker, s *grpc.Server) error {
	f.Impl.Init()
	vagrant_proto.RegisterSyncedFolderServer(s,
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
	client := vagrant_proto.NewSyncedFolderClient(c)
	return &GRPCSyncedFolderClient{
		GRPCIOClient: GRPCIOClient{
			client:  client,
			doneCtx: ctx},
		GRPCGuestCapabilitiesClient: GRPCGuestCapabilitiesClient{
			client:  client,
			doneCtx: ctx},
		GRPCHostCapabilitiesClient: GRPCHostCapabilitiesClient{
			client:  client,
			doneCtx: ctx},
		client:  client,
		doneCtx: ctx}, nil
}
