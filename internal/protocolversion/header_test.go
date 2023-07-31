// Copyright (c) HashiCorp, Inc.
// SPDX-License-Identifier: MIT

package protocolversion

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestParseHeader(t *testing.T) {
	cases := []struct {
		Name         string
		Input        string
		Err          string
		Min, Current uint32
	}{
		{
			"blank",
			"",
			"must be formatted",
			0, 0,
		},

		{
			"correct",
			"1,2",
			"",
			1, 2,
		},

		{
			"incomplete",
			"1,",
			"formatted",
			0, 0,
		},
	}

	for _, tt := range cases {
		t.Run(tt.Name, func(t *testing.T) {
			require := require.New(t)

			min, current, err := ParseHeader(tt.Input)
			if tt.Err != "" {
				require.Error(err)
				require.Contains(err.Error(), tt.Err)
				return
			}

			require.NoError(err)
			require.Equal(tt.Min, min)
			require.Equal(tt.Current, current)
		})
	}
}
