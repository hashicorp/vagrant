package ptypes

import (
	"errors"
	"reflect"

	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestJobNew(t testing.T, src *vagrant_server.Job) *vagrant_server.Job {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Job{}
	}

	require.NoError(t, mergo.Merge(src, &vagrant_server.Job{
		Scope: &vagrant_server.Job_Target{
			Target: &vagrant_plugin_sdk.Ref_Target{
				ResourceId: "TESTMACH",
				Project: &vagrant_plugin_sdk.Ref_Project{
					ResourceId: "TESTPROJ",
					Basis: &vagrant_plugin_sdk.Ref_Basis{
						ResourceId: "TESTBAS",
					},
				},
			},
		},
		TargetRunner: &vagrant_server.Ref_Runner{
			Target: &vagrant_server.Ref_Runner_Any{
				Any: &vagrant_server.Ref_RunnerAny{},
			},
		},
		DataSource: &vagrant_server.Job_DataSource{
			Source: &vagrant_server.Job_DataSource_Local{
				Local: &vagrant_server.Job_Local{},
			},
		},
		Operation: &vagrant_server.Job_Noop_{
			Noop: &vagrant_server.Job_Noop{},
		},
	}))

	return src
}

// ValidateJob validates the job structure.
func ValidateJob(job *vagrant_server.Job) error {
	return validation.ValidateStruct(job,
		validation.Field(&job.Id, validation.By(isEmpty)),
		validation.Field(&job.TargetRunner, validation.Required),
		validation.Field(&job.Operation, validation.Required),
	)
}

func isEmpty(v interface{}) error {
	if reflect.ValueOf(v).IsZero() {
		return nil
	}

	return errors.New("must be empty")
}
