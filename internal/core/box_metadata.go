package core

import "github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"

type BoxMetadata struct {
	metadata *vagrant_server.BoxMetadata
}

func LoadBoxMetadata() (*BoxMetadata, error) {
	// TODO
	return &BoxMetadata{}, nil
}

func (b *BoxMetadata) Version(version string) (v *BoxVersion, err error) {
	v, err = LoadBoxVersion()
	return
}

func (b *BoxMetadata) Versions() ([]string, error) {
	// TODO
	return []string{}, nil
}

type BoxVersion struct {
	version *vagrant_server.BoxMetadata_Version
}

func LoadBoxVersion() (*BoxVersion, error) {
	// TODO
	return &BoxVersion{}, nil
}

func (b *BoxVersion) Provider(name string) (p *BoxVersionProvider, err error) {
	p, err = LoadBoxVersionProvider()
	return
}

func (b *BoxVersion) Providers() ([]string, error) {
	// TODO
	return []string{}, nil
}

type BoxVersionProvider struct {
	provider *vagrant_server.BoxMetadata_Version_Provider
}

func LoadBoxVersionProvider() (*BoxVersionProvider, error) {
	// TODO
	return &BoxVersionProvider{}, nil
}
