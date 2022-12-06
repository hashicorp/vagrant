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

	t.Run("Put and Get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			ResourceId: "test",
			Name:       "test_name",
			Path:       "/User/test/test",
		}

		testBasisRef := &vagrant_plugin_sdk.Ref_Basis{
			ResourceId: "test",
			Name:       "test_name",
			Path:       "/User/test/test",
		}

		// Set
		err := s.BasisPut(testBasis)
		require.NoError(err)

		// Get full ref
		{
			resp, err := s.BasisGet(testBasisRef)
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBasis.Name)
		}

		// Get by id
		{
			resp, err := s.BasisGet(&vagrant_plugin_sdk.Ref_Basis{
				ResourceId: "test",
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBasis.Name)
		}
	})

	t.Run("Find", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBasis := &vagrant_server.Basis{
			ResourceId: "test",
			Name:       "test_name",
			Path:       "/User/test/test",
		}

		// Set
		err := s.BasisPut(testBasis)
		require.NoError(err)

		// Find by resource id
		{
			resp, err := s.BasisFind(&vagrant_server.Basis{
				ResourceId: "test",
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
			ResourceId: "test",
			Name:       "test_name",
			Path:       "/User/test/test",
		}

		testBasisRef := &vagrant_plugin_sdk.Ref_Basis{ResourceId: "test"}

		// Does not throw error if basis does not exist
		err := s.BasisDelete(testBasisRef)
		require.NoError(err)

		// Add basis
		err = s.BasisPut(testBasis)
		require.NoError(err)

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
		err := s.BasisPut(&vagrant_server.Basis{
			ResourceId: "test",
			Name:       "test_name",
			Path:       "/User/test/test",
		})
		require.NoError(err)

		err = s.BasisPut(&vagrant_server.Basis{
			ResourceId: "test2",
			Name:       "test_name2",
			Path:       "/User/test/test2",
		})
		require.NoError(err)

		b, err := s.BasisList()
		require.NoError(err)
		require.Len(b, 2)
	})
}
