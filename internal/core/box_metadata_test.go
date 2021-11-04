package core

import (
	"testing"

	"github.com/stretchr/testify/require"
)

var rawMetadata = `{
	"description": "something about a box",
	"name": "test/box",
	"versions": [{
			"version": "1.2.3",
			"status": "active",
			"description": "does things",
			"providers": [{
					"name": "virtualbox",
					"url": "http://doesnotexist"
				},
				{
					"name": "vmware",
					"url": "http://doesnotexist"
				}
			]
		},
		{
			"version": "0.1.2",
			"status": "active",
			"description": "does not do things",
			"providers": [{
				"name": "virtualbox",
				"url": "http://doesnotexist"
			}]
		}
	]
}`

func loadMetadata(t *testing.T, d []byte) *BoxMetadata {
	metadata, err := LoadBoxMetadata(d)
	if err != nil {
		t.Errorf("Failed to load metadata")
	}
	return metadata
}

func loadVersion(t *testing.T, d []byte, v string) *BoxVersion {
	metadata := loadMetadata(t, d)
	version, err := metadata.Version(v)
	if err != nil {
		t.Errorf("Failed to get version")
	}
	return version
}

func loadProvider(t *testing.T, d []byte, v string, p string) *BoxVersionProvider {
	version := loadVersion(t, d, v)
	provider, err := version.Provider(p)
	if err != nil {
		t.Errorf("Failed to get provider")
	}
	return provider
}

func TestLoadMetadata(t *testing.T) {
	metadata := loadMetadata(t, []byte(rawMetadata))
	if metadata.Name != "test/box" {
		t.Errorf("Could not parse box info")
	}
}

func TestListVersions(t *testing.T) {
	metadata := loadMetadata(t, []byte(rawMetadata))

	versions, err := metadata.ListVersions()
	if err != nil {
		t.Errorf("Failed to list versions")
	}
	require.Contains(t, versions, "1.2.3")
	require.Contains(t, versions, "0.1.2")
}

func TestGetVersion(t *testing.T) {
	version := loadVersion(t, []byte(rawMetadata), "1.2.3")
	require.NotNil(t, version)
	neVersion := loadVersion(t, []byte(rawMetadata), "0.0.0")
	require.Nil(t, neVersion)
}

func TestVersionListProviders(t *testing.T) {
	version := loadVersion(t, []byte(rawMetadata), "1.2.3")
	providers, err := version.ListProviders()
	if err != nil {
		t.Errorf("Failed to list providers")
	}
	require.Contains(t, providers, "virtualbox")
	require.Contains(t, providers, "vmware")
}

func TestVersionGetProvider(t *testing.T) {
	provider := loadProvider(t, []byte(rawMetadata), "1.2.3", "virtualbox")
	require.NotNil(t, provider)
	neProvider := loadProvider(t, []byte(rawMetadata), "1.2.3", "idontexist")
	require.Nil(t, neProvider)
}
