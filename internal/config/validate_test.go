// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package config

// TODO: renable these tests when vagrantfile's can be parsed in hcl
// import (
// 	"path/filepath"
// 	"testing"

// 	"github.com/stretchr/testify/require"
// )
//
// func TestConfigValidate(t *testing.T) {
// 	cases := []struct {
// 		File string
// 		Err  string
// 	}{
// 		{
// 			"valid.hcl",
// 			"",
// 		},

// 		{
// 			"no_build.hcl",
// 			"'build' stanza",
// 		},
// 	}

// 	for _, tt := range cases {
// 		t.Run(tt.File, func(t *testing.T) {
// 			require := require.New(t)

// 			cfg, err := Load(filepath.Join("testdata", "validate", tt.File), "")
// 			require.NoError(err)

// 			err = cfg.Validate()
// 			if tt.Err == "" {
// 				require.NoError(err)
// 				return
// 			}

// 			require.Error(err)
// 			require.Contains(err.Error(), tt.Err)
// 		})
// 	}
// }
