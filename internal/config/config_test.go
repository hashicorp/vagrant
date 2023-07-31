// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

// TODO: renable these tests when vagrantfile's can be parsed in hcl
// func TestLoad_compare(t *testing.T) {
// 	cases := []struct {
// 		File string
// 		Err  string
// 		Func func(*testing.T, *Config)
// 	}{
// 		{
// 			"project.hcl",
// 			"",
// 			func(t *testing.T, c *Config) {
// 				require.Equal(t, "hello", c.Project)
// 			},
// 		},

// 		{
// 			"project_pwd.hcl",
// 			"",
// 			func(t *testing.T, c *Config) {
// 				require.NotEmpty(t, c.Project)
// 			},
// 		},

// 		{
// 			"project_path_project.hcl",
// 			"",
// 			func(t *testing.T, c *Config) {
// 				expected, err := filepath.Abs(filepath.Join("testdata", "compare"))
// 				require.NoError(t, err)
// 				require.Equal(t, expected, c.Project)
// 			},
// 		},

// 		{
// 			"project_function.hcl",
// 			"",
// 			func(t *testing.T, c *Config) {
// 				require.Equal(t, "HELLO", c.Project)
// 			},
// 		},
// 	}

// 	for _, tt := range cases {
// 		t.Run(tt.File, func(t *testing.T) {
// 			require := require.New(t)

// 			cfg, err := Load(filepath.Join("testdata", "compare", tt.File), "")
// 			if tt.Err != "" {
// 				require.Error(err)
// 				require.Contains(err.Error(), tt.Err)
// 				return
// 			}
// 			require.NoError(err)

// 			tt.Func(t, cfg)
// 		})
// 	}
// }
