package state

import (
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
)

func TestTarget(t *testing.T) {
	t.Run("Get returns not found error if not exist", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		// Set
		_, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
			ResourceId: "foo",
		})
		require.Error(err)
		require.Equal(codes.NotFound, status.Code(err))
	})

	t.Run("Put and Get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projectRef := testProject(t, s)

		resourceId := "AbCdE"
		// Set
		err := s.TargetPut(serverptypes.TestTarget(t, &vagrant_server.Target{
			ResourceId: resourceId,
			Project:    projectRef,
			Name:       "test",
		}))
		require.NoError(err)

		// Get exact
		{
			resp, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
				ResourceId: resourceId,
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.ResourceId, resourceId)

		}

		// List
		{
			resp, err := s.TargetList()
			require.NoError(err)
			require.Len(resp, 1)
		}
	})

	t.Run("Delete", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projectRef := testProject(t, s)

		resourceId := "AbCdE"
		// Set
		err := s.TargetPut(serverptypes.TestTarget(t, &vagrant_server.Target{
			ResourceId: resourceId,
			Project:    projectRef,
			Name:       "test",
		}))
		require.NoError(err)

		// Read
		resp, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
			ResourceId: resourceId,
		})
		require.NoError(err)
		require.NotNil(resp)

		// Delete
		{
			err := s.TargetDelete(&vagrant_plugin_sdk.Ref_Target{
				ResourceId: resourceId,
				Project:    projectRef,
			})
			require.NoError(err)
		}

		// Read
		{
			_, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
				ResourceId: resourceId,
			})
			require.Error(err)
			require.Equal(codes.NotFound, status.Code(err))
		}

		// List
		{
			resp, err := s.TargetList()
			require.NoError(err)
			require.Len(resp, 0)
		}
	})
}
