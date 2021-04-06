package config

import (
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestConfigAppPlugins(t *testing.T) {
	cases := []struct {
		File       string
		TestAll    func(*testing.T, []*Plugin)
		TestByName map[string]func(*testing.T, *Plugin)
	}{
		{
			"none.hcl",
			func(t *testing.T, ps []*Plugin) {
				require.Empty(t, ps)
			},
			nil,
		},

		{
			"explicit.hcl",
			func(t *testing.T, ps []*Plugin) {
				require.Len(t, ps, 2)
			},
			map[string]func(*testing.T, *Plugin){
				"go1": func(t *testing.T, p *Plugin) {
					require.True(t, p.Type.Mapper)
					require.False(t, p.Type.Registry)
				},

				"go2": func(t *testing.T, p *Plugin) {
					require.False(t, p.Type.Mapper)
					require.True(t, p.Type.Registry)
				},
			},
		},

		{
			"implicit.hcl",
			func(t *testing.T, ps []*Plugin) {
				require.Len(t, ps, 2)
			},
			map[string]func(*testing.T, *Plugin){
				"docker": func(t *testing.T, p *Plugin) {
					require.True(t, p.Type.Builder)
					require.False(t, p.Type.Platform)
					require.True(t, p.Type.Mapper)
				},

				"nomad": func(t *testing.T, p *Plugin) {
					require.False(t, p.Type.Builder)
					require.True(t, p.Type.Platform)
					require.True(t, p.Type.Mapper)
				},
			},
		},

		{
			"implicit_registry.hcl",
			func(t *testing.T, ps []*Plugin) {
				require.Len(t, ps, 3)
			},
			map[string]func(*testing.T, *Plugin){
				"docker": func(t *testing.T, p *Plugin) {
					require.True(t, p.Type.Builder)
					require.False(t, p.Type.Platform)
				},

				"aws-ecr": func(t *testing.T, p *Plugin) {
					require.False(t, p.Type.Builder)
					require.True(t, p.Type.Registry)
				},

				"nomad": func(t *testing.T, p *Plugin) {
					require.False(t, p.Type.Builder)
					require.True(t, p.Type.Platform)
				},
			},
		},

		{
			"mix.hcl",
			func(t *testing.T, ps []*Plugin) {
				require.Len(t, ps, 2)
			},
			map[string]func(*testing.T, *Plugin){
				"docker": func(t *testing.T, p *Plugin) {
					require.True(t, p.Type.Builder)
					require.True(t, p.Type.Platform)
				},

				"nomad": func(t *testing.T, p *Plugin) {
					require.False(t, p.Type.Builder)
					require.True(t, p.Type.Platform)
				},
			},
		},
	}

	for _, tt := range cases {
		t.Run(tt.File, func(t *testing.T) {
			require := require.New(t)

			cfg, err := Load(filepath.Join("testdata", "plugins", tt.File), "")
			require.NoError(err)

			ps := cfg.Plugins()
			tt.TestAll(t, ps)

			psMap := map[string]*Plugin{}
			for _, p := range ps {
				if _, ok := psMap[p.Name]; ok {
					t.Fatal("duplicate plugin: " + p.Name)
				}

				psMap[p.Name] = p
			}

			for n, f := range tt.TestByName {
				f(t, psMap[n])
			}
		})
	}
}
