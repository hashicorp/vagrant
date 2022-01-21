package myplugin

// import (
// 	"context"

// 	"github.com/hashicorp/vagrant-plugin-sdk/component"
// 	"github.com/hashicorp/vagrant-plugin-sdk/docs"
// 	"github.com/hashicorp/vagrant-plugin-sdk/multistep"
// 	pb "github.com/hashicorp/vagrant/builtin/myplugin/proto"
// )

// type ProviderConfig struct {
// }

// // Provider is the Provider implementation for myplugin.
// type Provider struct {
// 	config ProviderConfig
// }

// // Config implements Configurable
// func (p *Provider) Config() (interface{}, error) {
// 	return &p.config, nil
// }

// func (b *Provider) Documentation() (*docs.Documentation, error) {
// 	doc, err := docs.New(docs.FromConfig(&ProviderConfig{}))
// 	if err != nil {
// 		return nil, err
// 	}
// 	return doc, nil
// }

// // UsableFunc implements component.Provider
// func (p *Provider) UsableFunc() interface{} {
// 	return p.Usable
// }

// // InstalledFunc implements component.Provider
// func (p *Provider) InstalledFunc() interface{} {
// 	return p.Installed
// }

// // InitFunc implements component.Provider
// func (p *Provider) InitFunc() interface{} {
// 	return p.Init
// }

// // ActionUpFunc implements component.Provider
// func (p *Provider) ActionUpFunc() interface{} {
// 	return p.ActionUp
// }

// // TODO
// func (p *Provider) Usable() (bool, error) {
// 	return true, nil
// }

// func (p *Provider) Installed(context.Context) (bool, error) {
// 	return true, nil
// }

// // TODO
// func (p *Provider) Init() (bool, error) {
// 	return true, nil
// }

// // TODO: Take an implementation of core.Machine as an input
// func (c *Provider) ActionUp(ctx context.Context, statebag *multistep.BasicStateBag) (*pb.UpResult, error) {
// 	return &pb.UpResult{}, nil
// }

// var (
// 	_ component.Provider     = (*Provider)(nil)
// 	_ component.Configurable = (*Provider)(nil)
// )
