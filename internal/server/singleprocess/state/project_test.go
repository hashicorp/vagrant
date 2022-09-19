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

func TestProject(t *testing.T) {
	t.Run("Get returns not found error if not exist", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		// Set
		_, err := s.ProjectGet(&vagrant_plugin_sdk.Ref_Project{
			ResourceId: "foo",
		})
		require.Error(err)
		require.Equal(codes.NotFound, status.Code(err))
	})

	t.Run("Put and Get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		basisRef := testBasis(t, s)

		// Set
		result, err := s.ProjectPut(serverptypes.TestProject(t, &vagrant_server.Project{
			Basis: basisRef,
			Path:  "idontexist",
		}))
		require.NoError(err)

		// Get exact
		{
			resp, err := s.ProjectGet(&vagrant_plugin_sdk.Ref_Project{
				ResourceId: result.ResourceId,
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.ResourceId, result.ResourceId)

		}

		// List
		{
			resp, err := s.ProjectList()
			require.NoError(err)
			require.Len(resp, 1)
		}
	})

	t.Run("Delete", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		basisRef := testBasis(t, s)

		// Set
		result, err := s.ProjectPut(serverptypes.TestProject(t, &vagrant_server.Project{
			Basis: basisRef,
			Path:  "idontexist",
		}))
		require.NoError(err)

		// Read
		resp, err := s.ProjectGet(&vagrant_plugin_sdk.Ref_Project{
			ResourceId: result.ResourceId,
		})
		require.NoError(err)
		require.NotNil(resp)

		// Delete
		{
			err := s.ProjectDelete(&vagrant_plugin_sdk.Ref_Project{
				ResourceId: result.ResourceId,
				Basis:      basisRef,
			})
			require.NoError(err)
		}

		// Read
		{
			_, err := s.ProjectGet(&vagrant_plugin_sdk.Ref_Project{
				ResourceId: result.ResourceId,
			})
			require.Error(err)
			require.Equal(codes.NotFound, status.Code(err))
		}

		// List
		{
			resp, err := s.ProjectList()
			require.NoError(err)
			require.Len(resp, 0)
		}
	})
}
