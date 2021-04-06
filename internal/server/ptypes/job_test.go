package ptypes

import (
	"testing"

	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestValidateJob(t *testing.T) {
	cases := []struct {
		Name   string
		Modify func(*vagrant_server.Job)
		Error  string
	}{
		{
			"valid",
			nil,
			"",
		},

		{
			"id is set",
			func(j *vagrant_server.Job) { j.Id = "nope" },
			"id: must be empty",
		},
	}

	for _, tt := range cases {
		t.Run(tt.Name, func(t *testing.T) {
			require := require.New(t)

			job := TestJobNew(t, nil)
			if f := tt.Modify; f != nil {
				f(job)
			}

			err := ValidateJob(job)
			if tt.Error == "" {
				require.NoError(err)
				return
			}

			require.Error(err)
			require.Contains(err.Error(), tt.Error)
		})
	}
}
