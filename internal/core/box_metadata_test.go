// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package core

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
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

func loadVersion(t *testing.T, d []byte, v string) (core.BoxMetadata, *core.BoxVersion) {
	metadata := loadMetadata(t, d)
	version, err := metadata.Version(v, nil)
	if err != nil {
		t.Errorf("Failed to get version")
	}
	return metadata, version
}

func loadProvider(t *testing.T, d []byte, v string, p string) (core.BoxMetadata, *core.BoxProvider) {
	metadata, version := loadVersion(t, d, v)
	provider, err := metadata.Provider(version.Version, p)
	if err != nil {
		t.Errorf("Failed to get provider")
	}
	return metadata, provider
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

func TestListVersionsWithQuery(t *testing.T) {
	metadata := loadMetadata(t, []byte(rawMetadata))

	versions, err := metadata.ListVersions(&core.BoxProvider{Name: "virtualbox"})
	if err != nil {
		t.Errorf("Failed to list versions")
	}
	require.Contains(t, versions, "1.2.3")
	require.Contains(t, versions, "0.1.2")

	versions2, err := metadata.ListVersions(&core.BoxProvider{Name: "vmware"})
	if err != nil {
		t.Errorf("Failed to list versions")
	}
	require.Contains(t, versions2, "1.2.3")
	require.NotContains(t, versions2, "0.1.2")
}

func TestGetVersion(t *testing.T) {
	_, version := loadVersion(t, []byte(rawMetadata), "1.2.3")
	require.NotNil(t, version)
	_, constrainedVersion := loadVersion(t, []byte(rawMetadata), ">1.0.0")
	require.NotNil(t, constrainedVersion)
	_, neVersion := loadVersion(t, []byte(rawMetadata), "0.0.0")
	require.Nil(t, neVersion)
}

func TestGetVersionWithQuery(t *testing.T) {
	metadata := loadMetadata(t, []byte(rawMetadata))

	version, err := metadata.Version("1.2.3")
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.NotNil(t, version)

	version, err = metadata.Version("1.2.3", &core.BoxProvider{Name: "virtualbox"})
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.NotNil(t, version)

	version, err = metadata.Version("1.2.3", &core.BoxProvider{Name: "virtualbox"}, &core.BoxProvider{Name: "idontexist"})
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.NotNil(t, version)

	version, err = metadata.Version("1.2.3", &core.BoxProvider{Name: "idontexist"}, &core.BoxProvider{Name: "vmware"})
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.NotNil(t, version)

	version2, err := metadata.Version("1.2.3", &core.BoxProvider{Name: "asdf"})
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.Nil(t, version2)
}

func TestVersionListProviders(t *testing.T) {
	metadata, version := loadVersion(t, []byte(rawMetadata), "1.2.3")
	providers, err := metadata.ListProviders(version.Version)
	if err != nil {
		t.Errorf("Failed to list providers")
	}
	require.Contains(t, providers, "virtualbox")
	require.Contains(t, providers, "vmware")
}

func TestVersionGetProvider(t *testing.T) {
	_, provider := loadProvider(t, []byte(rawMetadata), "1.2.3", "virtualbox")
	require.NotNil(t, provider)
	_, neProvider := loadProvider(t, []byte(rawMetadata), "1.2.3", "idontexist")
	require.Nil(t, neProvider)
}

func TestProviderMatches(t *testing.T) {
	version := "1.2.3"
	providerName := "virtualbox"

	metadata, err := LoadBoxMetadata([]byte(rawMetadata))
	if err != nil {
		t.Error(err)
	}

	matches, err := metadata.matches(version, providerName, &core.BoxProvider{Name: "virtualbox"})
	require.True(t, matches)
	require.NoError(t, err)

	matches, err = metadata.matches(version, providerName, &core.BoxProvider{Url: "http://doesnotexist"})
	require.True(t, matches)
	require.NoError(t, err)

	matches, err = metadata.matches(version, providerName, &core.BoxProvider{})
	require.True(t, matches)
	require.NoError(t, err)

	matches, err = metadata.matches(version, providerName, &core.BoxProvider{Name: "virtualbox", Url: "http://doesnotexist"})
	require.True(t, matches)
	require.NoError(t, err)

	matches, err = metadata.matches(version, providerName, &core.BoxProvider{Name: "nope", Url: "http://doesnotexist"})
	require.False(t, matches)
	require.NoError(t, err)

	matches, err = metadata.matches(version, providerName, &core.BoxProvider{Name: "vmware"})
	require.False(t, matches)
	require.NoError(t, err)
}

func TestProviderMatchesAny(t *testing.T) {
	version := "1.2.3"
	providerName := "virtualbox"

	metadata, err := LoadBoxMetadata([]byte(rawMetadata))
	if err != nil {
		t.Error(err)
	}

	m, err := metadata.matchesAny(version, providerName, &core.BoxProvider{Name: "virtualbox"})
	require.True(t, m)
	require.NoError(t, err)

	m, err = metadata.matchesAny(version, providerName,
		&core.BoxProvider{Name: "virtualbox"}, &core.BoxProvider{Name: "nope"})
	require.True(t, m)
	require.NoError(t, err)

	m, err = metadata.matchesAny(version, providerName,
		&core.BoxProvider{Url: "nope"}, &core.BoxProvider{Name: "nope"})
	require.False(t, m)
	require.NoError(t, err)

	m, err = metadata.matchesAny(version, providerName)
	require.False(t, m)
	require.NoError(t, err)
}
