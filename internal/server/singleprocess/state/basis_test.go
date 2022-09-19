package state

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestBasis(t *testing.T) {
	t.Run("Get returns error if not exist", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		_, err := s.BasisGet(&vagrant_plugin_sdk.Ref_Basis{ResourceId: "nothing"})
		require.Error(err)
	})

	t.Run("Put creates and sets resource ID", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			Name: "test_name",
			Path: "/User/test/test",
		}

		result, err := s.BasisPut(testBasis)
		require.NoError(err)
		require.NotEmpty(result.ResourceId)
	})

	t.Run("Put fails on duplicate name", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			Name: "test_name",
			Path: "/User/test/test",
		}

		// Set initial record
		_, err := s.BasisPut(testBasis)
		require.NoError(err)

		// Attempt to set it again
		_, err = s.BasisPut(testBasis)
		require.Error(err)
	})

	t.Run("Put and Get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			Name: "test_name",
			Path: "/User/test/test",
		}

		// Set
		result, err := s.BasisPut(testBasis)
		require.NoError(err)

		testBasisRef := &vagrant_plugin_sdk.Ref_Basis{
			ResourceId: result.ResourceId,
		}

		// Get full ref
		resp, err := s.BasisGet(testBasisRef)
		require.NoError(err)
		require.NotNil(resp)
		require.Equal(resp.Name, testBasis.Name)
	})

	t.Run("Find", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			Name: "test_name",
			Path: "/User/test/test",
		}

		// Set
		result, err := s.BasisPut(testBasis)
		require.NoError(err)

		// Find by resource id
		{
			resp, err := s.BasisFind(&vagrant_server.Basis{
				ResourceId: result.ResourceId,
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBasis.Name)
		}

		// Find by name
		{
			resp, err := s.BasisFind(&vagrant_server.Basis{
				Name: "test_name",
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBasis.Name)
		}

		// Find by path
		{
			resp, err := s.BasisFind(&vagrant_server.Basis{
				Path: "/User/test/test",
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBasis.Name)
		}
	})

	t.Run("Delete", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			Name: "test_name",
			Path: "/User/test/test",
		}

		testBasisRef := &vagrant_plugin_sdk.Ref_Basis{ResourceId: "test"}

		// Does not throw error if basis does not exist
		err := s.BasisDelete(testBasisRef)
		require.NoError(err)

		// Add basis
		result, err := s.BasisPut(testBasis)
		require.NoError(err)
		testBasisRef.ResourceId = result.ResourceId

		// No error when deleting basis
		err = s.BasisDelete(testBasisRef)
		require.NoError(err)

		// Basis should not exist
		_, err = s.BasisGet(testBasisRef)
		require.Error(err)
	})

	t.Run("List", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		// Add basis'
		_, err := s.BasisPut(&vagrant_server.Basis{
			Name: "test_name",
			Path: "/User/test/test",
		})
		require.NoError(err)

		_, err = s.BasisPut(&vagrant_server.Basis{
			Name: "test_name2",
			Path: "/User/test/test2",
		})
		require.NoError(err)

		b, err := s.BasisList()
		require.NoError(err)
		require.Len(b, 2)
	})
}
