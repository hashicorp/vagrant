package plugin

import (
	"context"
	"encoding/json"

	"google.golang.org/grpc"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_common"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_folder"

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
	client  vagrant_folder.SyncedFolderClient
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
	_, err = c.client.Cleanup(jctx, &vagrant_folder.CleanupRequest{
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
	_, err = c.client.Disable(jctx, &vagrant_folder.Request{
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
	_, err = c.client.Enable(jctx, &vagrant_folder.Request{
		Machine: machine,
		Folders: string(folders),
		Options: string(opts)})
	return handleGrpcError(err, c.doneCtx, ctx)
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

func (c *GRPCSyncedFolderClient) IsUsable(ctx context.Context, m *vagrant.Machine) (u bool, err error) {
	machine, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	jctx, _ := joincontext.Join(ctx, c.doneCtx)
	resp, err := c.client.IsUsable(jctx, &vagrant_common.EmptyRequest{
		Machine: machine})
	if err != nil {
		return false, handleGrpcError(err, c.doneCtx, ctx)
	}
	u = resp.Result
	return
}

func (c *GRPCSyncedFolderClient) Name() string {
	resp, err := c.client.Name(context.Background(), &vagrant_common.NullRequest{})
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
	_, err = c.client.Prepare(jctx, &vagrant_folder.Request{
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
	n := make(chan struct{})
	go func() {
		err = s.Impl.Cleanup(ctx, machine, options)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
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
	n := make(chan struct{})
	go func() {
		err = s.Impl.Disable(ctx, machine, folders, options)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
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
	n := make(chan struct{})
	go func() {
		err = s.Impl.Enable(ctx, machine, folders, options)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
	}
	return
}

func (s *GRPCSyncedFolderServer) Info(ctx context.Context, req *vagrant_common.NullRequest) (*vagrant_folder.InfoResponse, error) {
	n := make(chan struct{})
	var r *vagrant.SyncedFolderInfo
	go func() {
		r = s.Impl.Info()
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
		return nil, nil
	case <-n:
	}
	return &vagrant_folder.InfoResponse{
		Description: r.Description,
		Priority:    r.Priority}, nil
}

func (s *GRPCSyncedFolderServer) IsUsable(ctx context.Context, req *vagrant_common.EmptyRequest) (resp *vagrant_common.IsResponse, err error) {
	resp = &vagrant_common.IsResponse{}
	var r bool
	machine, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		return
	}
	n := make(chan struct{})
	go func() {
		r, err = s.Impl.IsUsable(ctx, machine)
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

func (s *GRPCSyncedFolderServer) Name(_ context.Context, req *vagrant_common.NullRequest) (*vagrant_common.NameResponse, error) {
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
	n := make(chan struct{})
	go func() {
		err = s.Impl.Prepare(ctx, machine, folders, options)
		n <- struct{}{}
	}()
	select {
	case <-ctx.Done():
	case <-n:
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
