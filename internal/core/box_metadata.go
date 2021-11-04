package core

import (
	"encoding/json"

	"github.com/mitchellh/mapstructure"
)

type BoxVersionProvider struct {
	// provider *vagrant_server.BoxMetadata_Version_Provider
	Name         string
	Url          string
	Checksum     string
	ChecksumType string
}

type BoxVersion struct {
	// version *vagrant_server.BoxMetadata_Version
	Version     string
	State       string
	Description string
	Providers   []*BoxVersionProvider
}

func (b *BoxVersion) Provider(name string) (p *BoxVersionProvider, err error) {
	for _, provider := range b.Providers {
		if provider.Name == name {
			return provider, nil
		}
	}
	return
}

func (b *BoxVersion) ListProviders() ([]string, error) {
	p := []string{}
	for _, provider := range b.Providers {
		p = append(p, provider.Name)
	}
	return p, nil
}

type BoxMetadata struct {
	Name        string
	Description string
	Versions    []*BoxVersion
	// metadata *vagrant_server.BoxMetadata
}

func LoadBoxMetadata(data []byte) (*BoxMetadata, error) {
	var metadata map[string]interface{}
	if err := json.Unmarshal(data, &metadata); err != nil {
		return nil, err
	}
	var result BoxMetadata
	return &result, mapstructure.Decode(metadata, &result)
}

func (b *BoxMetadata) Version(version string) (v *BoxVersion, err error) {
	for _, ver := range b.Versions {
		if ver.Version == version {
			return ver, nil
		}
	}
	return
}

func (b *BoxMetadata) ListVersions() ([]string, error) {
	v := []string{}
	for _, version := range b.Versions {
		v = append(v, version.Version)
	}
	return v, nil
}
