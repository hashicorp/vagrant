package core

import (
	"encoding/json"
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
	name        string
	description string
	versions    []*BoxVersion
}

func LoadBoxMetadata(data []byte) (*BoxMetadata, error) {
	var metadata map[string]interface{}
	if err := json.Unmarshal(data, &metadata); err != nil {
		return nil, err
	}
	var result BoxMetadata
	return &result, mapstructure.Decode(metadata, &result)
}

func (b *BoxMetadata) Name() string {
	return b.name
}

func (b *BoxMetadata) Version(ver string, providerOpts *core.BoxProvider) (v *core.BoxVersion, err error) {
	matchesProvider := false
	inputVersion, err := version.NewConstraint(ver)
	if err != nil {
		return nil, err
	}
	for _, boxVer := range b.versions {
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
				var coreBoxVersion *core.BoxVersion
				mapstructure.Decode(boxVer, &coreBoxVersion)
				return coreBoxVersion, nil
			}
		}
	}
	return
}

func (b *BoxMetadata) ListVersions(providerOpts ...*core.BoxProvider) ([]string, error) {
	v := []string{}
	for _, version := range b.versions {
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

func (b *BoxMetadata) Provider(version string, name string) (provider *core.BoxProvider, err error) {
	return
}

func (b *BoxMetadata) ListProviders(version string) (providers []string, err error) {
	return
}

var _ core.BoxMetadata = (*BoxMetadata)(nil)
