package ptypes

import (
	validation "github.com/go-ozzo/ozzo-validation/v4"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// TestTarget returns a valid target for tests.
func TestTarget(t testing.T, src *vagrant_server.Target) *vagrant_server.Target {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Target{}
	}

	require.NoError(t, mergo.Merge(src, &vagrant_server.Target{
		Name:    "test",
		Project: &vagrant_plugin_sdk.Ref_Project{},
	}))

	return src
}

// ValidateTarget validates the target structure.
func ValidateTarget(t *vagrant_server.Target) error {
	return validation.ValidateStruct(t,
		validation.Field(&t.Name, validation.By(isEmpty)),
	)
}
