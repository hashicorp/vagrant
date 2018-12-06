package plugin

import (
	"context"
	"encoding/json"
	"errors"

	go_plugin "github.com/hashicorp/go-plugin"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_common"
	"github.com/hashicorp/vagrant/ext/go-plugin/vagrant/plugin/proto/vagrant_config"
)

type Config interface {
	vagrant.Config
	Meta
}

type ConfigPlugin struct {
	go_plugin.NetRPCUnsupportedPlugin
	Impl Config
}

type GRPCConfigServer struct {
	GRPCIOServer
	Impl Config
}

func (s *GRPCConfigServer) ConfigAttributes(ctx context.Context, req *vagrant_common.NullRequest) (resp *vagrant_config.AttributesResponse, err error) {
	resp = &vagrant_config.AttributesResponse{}
	r, e := s.Impl.ConfigAttributes()
	if e != nil {
		resp.Error = e.Error()
		return
	}
	resp.Attributes = r
	return
}

func (s *GRPCConfigServer) ConfigLoad(ctx context.Context, req *vagrant_config.LoadRequest) (resp *vagrant_config.LoadResponse, err error) {
	resp = &vagrant_config.LoadResponse{}
	var data map[string]interface{}
	err = json.Unmarshal([]byte(req.Data), &data)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	r, err := s.Impl.ConfigLoad(data)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	mdata, err := json.Marshal(r)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	resp.Data = string(mdata)
	return
}

func (s *GRPCConfigServer) ConfigValidate(ctx context.Context, req *vagrant_config.ValidateRequest) (resp *vagrant_config.ValidateResponse, err error) {
	resp = &vagrant_config.ValidateResponse{}
	var data map[string]interface{}
	err = json.Unmarshal([]byte(req.Data), &data)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	m, err := vagrant.LoadMachine(req.Machine, s.Impl)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	r, err := s.Impl.ConfigValidate(data, m)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	resp.Errors = r
	return
}

func (s *GRPCConfigServer) ConfigFinalize(ctx context.Context, req *vagrant_config.FinalizeRequest) (resp *vagrant_config.FinalizeResponse, err error) {
	resp = &vagrant_config.FinalizeResponse{}
	var data map[string]interface{}
	err = json.Unmarshal([]byte(req.Data), &data)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	r, err := s.Impl.ConfigFinalize(data)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	mdata, err := json.Marshal(r)
	if err != nil {
		resp.Error = err.Error()
		return
	}
	resp.Data = string(mdata)
	return
}

type GRPCConfigClient struct {
	client vagrant_config.ConfigClient
}

func (c *GRPCConfigClient) ConfigAttributes() (attrs []string, err error) {
	resp, err := c.client.ConfigAttributes(context.Background(), &vagrant_common.NullRequest{})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
	}
	attrs = resp.Attributes
	return
}

func (c *GRPCConfigClient) ConfigLoad(data map[string]interface{}) (loaddata map[string]interface{}, err error) {
	mdata, err := json.Marshal(data)
	if err != nil {
		return
	}
	resp, err := c.client.ConfigLoad(context.Background(), &vagrant_config.LoadRequest{
		Data: string(mdata)})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
		return
	}
	err = json.Unmarshal([]byte(resp.Data), &loaddata)
	return
}

func (c *GRPCConfigClient) ConfigValidate(data map[string]interface{}, m *vagrant.Machine) (errs []string, err error) {
	machData, err := vagrant.DumpMachine(m)
	if err != nil {
		return
	}
	mdata, err := json.Marshal(data)
	if err != nil {
		return
	}
	resp, err := c.client.ConfigValidate(context.Background(), &vagrant_config.ValidateRequest{
		Data:    string(mdata),
		Machine: machData})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
		return
	}
	errs = resp.Errors
	return
}

func (c *GRPCConfigClient) ConfigFinalize(data map[string]interface{}) (finaldata map[string]interface{}, err error) {
	mdata, err := json.Marshal(data)
	if err != nil {
		return
	}
	resp, err := c.client.ConfigFinalize(context.Background(), &vagrant_config.FinalizeRequest{
		Data: string(mdata)})
	if err != nil {
		return
	}
	if resp.Error != "" {
		err = errors.New(resp.Error)
		return
	}
	err = json.Unmarshal([]byte(resp.Data), &finaldata)
	return
}
