// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"encoding/json"
	"io/ioutil"
	"net/http"
	"reflect"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/mitchellh/mapstructure"
)

type BoxVersionProvider struct {
	Name         string
	Url          string
	Checksum     string
	ChecksumType string
}

func (b *BoxVersionProvider) MatchesAny(p ...*BoxVersionProvider) (matches bool) {
	for _, provider := range p {
		if b.Matches(provider) {
			return true
		}
	}
	return false
}

func (b *BoxVersionProvider) Matches(p *BoxVersionProvider) (matches bool) {
	pVal := reflect.ValueOf(*p)
	bVal := reflect.ValueOf(*b)
	typeOfMatcher := pVal.Type()
	matches = true

	fields := pVal.NumField()
	for i := 0; i < fields; i++ {
		if pVal.Field(i).Interface() != "" {
			bField := bVal.FieldByName(typeOfMatcher.Field(i).Name).Interface()
			pField := pVal.Field(i).Interface()
			if pField != bField {
				return false
			}
		}
	}
	return
}

type BoxVersion struct {
	Version     string
	Status      string
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
}

func LoadBoxMetadata(data []byte) (*BoxMetadata, error) {
	var metadata map[string]interface{}
	if err := json.Unmarshal(data, &metadata); err != nil {
		return nil, err
	}
	var result BoxMetadata
	err := mapstructure.Decode(metadata, &result)
	return &result, err
}

func (b *BoxMetadata) matches(version string, name string, p *core.BoxProvider) (matches bool, err error) {
	ver, err := b.version(version, &core.BoxProvider{Name: name})
	if err != nil {
		return false, err
	}
	provider, err := ver.Provider(name)
	if err != nil {
		return false, err
	}
	var boxVersionProvider *BoxVersionProvider
	mapstructure.Decode(p, &boxVersionProvider)
	return provider.Matches(boxVersionProvider), nil
}

func (b *BoxMetadata) matchesAny(version string, name string, p ...*core.BoxProvider) (matches bool, err error) {
	for _, provider := range p {
		m, err := b.matches(version, name, provider)
		if err != nil {
			return false, err
		}
		if m {
			return true, nil
		}
	}
	return false, nil
}

func (b *BoxMetadata) version(ver string, providerOpts *core.BoxProvider) (v *BoxVersion, err error) {
	matchesProvider := false
	inputVersion, err := version.NewConstraint(ver)
	if err != nil {
		return nil, err
	}
	for _, boxVer := range b.Versions {
		boxVersion, err := version.NewVersion(boxVer.Version)
		if err != nil {
			return nil, err
		}
		if inputVersion.Check(boxVersion) {
			// Check for the provider in the version
			if providerOpts == nil {
				matchesProvider = true
			} else {
				for _, p := range boxVer.Providers {
					boxVersionProvider := &BoxVersionProvider{
						Name: providerOpts.Name, Url: providerOpts.Url, Checksum: providerOpts.Checksum,
						ChecksumType: providerOpts.ChecksumType,
					}
					if p.Matches(boxVersionProvider) {
						matchesProvider = true
					}
				}
			}
			if matchesProvider {
				return boxVer, nil
			}
		}
	}
	return
}

func (b *BoxMetadata) LoadMetadata(url string) (err error) {
	client := &http.Client{}
	req, _ := http.NewRequest("GET", url, nil)
	req.Header.Set("Accept", "application/json")
	resp, err := client.Do(req)
	if err != nil {
		return err
	}
	defer resp.Body.Close()
	raw, err := ioutil.ReadAll(resp.Body)
	if err != nil {
		return err
	}
	var metadata map[string]interface{}
	if err := json.Unmarshal(raw, &metadata); err != nil {
		return err
	}
	err = mapstructure.Decode(metadata, &b)
	return
}

func (b *BoxMetadata) BoxName() string {
	return b.Name
}

func (b *BoxMetadata) Version(ver string, providerOpts ...*core.BoxProvider) (v *core.BoxVersion, err error) {
	if len(providerOpts) == 0 {
		providerOpts = []*core.BoxProvider{
			nil,
		}
	}
	for _, p := range providerOpts {
		boxVer, err := b.version(ver, p)
		if err != nil {
			return nil, err
		}
		if boxVer != nil {
			var coreBoxVersion *core.BoxVersion
			mapstructure.Decode(boxVer, &coreBoxVersion)
			return coreBoxVersion, nil
		}
	}
	return
}

func (b *BoxMetadata) ListVersions(providerOpts ...*core.BoxProvider) ([]string, error) {
	v := []string{}
	for _, version := range b.Versions {
		if providerOpts != nil {
			var boxVersionProvider []*BoxVersionProvider
			mapstructure.Decode(providerOpts, &boxVersionProvider)
			for _, p := range version.Providers {
				if p.MatchesAny(boxVersionProvider...) {
					v = append(v, version.Version)
				}
			}
		} else {
			v = append(v, version.Version)
		}
	}
	return v, nil
}

func (b *BoxMetadata) Provider(version string, name string) (p *core.BoxProvider, err error) {
	ver, err := b.version(version, &core.BoxProvider{Name: name})
	if err != nil {
		return nil, err
	}
	if ver == nil {
		return nil, err
	}
	provider, err := ver.Provider(name)
	if err != nil {
		return nil, err
	}
	if provider != nil {
		var coreProvider *core.BoxProvider
		mapstructure.Decode(provider, &coreProvider)
		var coreVersion *core.BoxVersion
		mapstructure.Decode(ver, &coreVersion)
		coreProvider.Version = coreVersion
		return coreProvider, nil
	}
	return
}

func (b *BoxMetadata) ListProviders(version string) (providers []string, err error) {
	ver, err := b.version(version, &core.BoxProvider{})
	if err != nil {
		return nil, err
	}
	return ver.ListProviders()
}

var _ core.BoxMetadata = (*BoxMetadata)(nil)
