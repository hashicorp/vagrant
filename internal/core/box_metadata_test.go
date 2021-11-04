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
	version, err := metadata.Version(v, nil)
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

func TestListVersionsWithQuery(t *testing.T) {
	metadata := loadMetadata(t, []byte(rawMetadata))

	versions, err := metadata.ListVersions(&BoxVersionProvider{Name: "virtualbox"})
	if err != nil {
		t.Errorf("Failed to list versions")
	}
	require.Contains(t, versions, "1.2.3")
	require.Contains(t, versions, "0.1.2")

	versions2, err := metadata.ListVersions(&BoxVersionProvider{Name: "vmware"})
	if err != nil {
		t.Errorf("Failed to list versions")
	}
	require.Contains(t, versions2, "1.2.3")
	require.NotContains(t, versions2, "0.1.2")
}

func TestGetVersion(t *testing.T) {
	version := loadVersion(t, []byte(rawMetadata), "1.2.3")
	require.NotNil(t, version)
	neVersion := loadVersion(t, []byte(rawMetadata), "0.0.0")
	require.Nil(t, neVersion)
}

func TestGetVersionWithQuery(t *testing.T) {
	metadata := loadMetadata(t, []byte(rawMetadata))

	version, err := metadata.Version("1.2.3", &BoxVersionProvider{Name: "virtualbox"})
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.NotNil(t, version)

	version2, err := metadata.Version("1.2.3", &BoxVersionProvider{Name: "asdf"})
	if err != nil {
		t.Errorf("Failed to get version")
	}
	require.Nil(t, version2)
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

func TestProviderMatches(t *testing.T) {
	provider := loadProvider(t, []byte(rawMetadata), "1.2.3", "virtualbox")
	require.True(
		t,
		provider.Matches(&BoxVersionProvider{Name: "virtualbox"}),
	)

	require.True(
		t,
		provider.Matches(&BoxVersionProvider{Url: "http://doesnotexist"}),
	)

	require.True(
		t,
		provider.Matches(&BoxVersionProvider{}),
	)

	require.True(
		t,
		provider.Matches(&BoxVersionProvider{Name: "virtualbox", Url: "http://doesnotexist"}),
	)

	require.False(
		t,
		provider.Matches(&BoxVersionProvider{Name: "nope", Url: "http://doesnotexist"}),
	)

	require.False(
		t,
		provider.Matches(&BoxVersionProvider{Name: "vmware"}),
	)
}

func TestProviderMatchesAny(t *testing.T) {
	provider := loadProvider(t, []byte(rawMetadata), "1.2.3", "virtualbox")
	require.True(
		t,
		provider.MatchesAny(
			&BoxVersionProvider{Name: "virtualbox"},
		),
	)

	require.True(
		t,
		provider.MatchesAny(
			&BoxVersionProvider{Name: "virtualbox"},
			&BoxVersionProvider{Name: "nope"},
		),
	)

	require.False(
		t,
		provider.MatchesAny(
			&BoxVersionProvider{Url: "nope"},
			&BoxVersionProvider{Name: "nope"},
		),
	)

	require.False(
		t,
		provider.MatchesAny(),
	)
}
