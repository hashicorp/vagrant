package state

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestSoftDecode(t *testing.T) {
	t.Run("Decodes nothing when unset", func(t *testing.T) {
		require := require.New(t)
		s := TestState(t)
		defer s.Close()

		tref := &vagrant_plugin_sdk.Target{}
		var target Target
		err := s.softDecode(tref, &target)
		require.NoError(err)
		require.Equal(target, Target{})
	})
	t.Run("Decodes project reference", func(t *testing.T) {
		require := require.New(t)
		s := TestState(t)
		defer s.Close()

		pref := testProject(t, s)
		tproto := &vagrant_server.Target{
			Project: pref,
		}

		var target Target
		err := s.softDecode(tproto, &target)

		require.NoError(err)
		require.NotNil(target.Project)
		require.Equal(*target.Project.ResourceId, tproto.Project.ResourceId)
	})
}
