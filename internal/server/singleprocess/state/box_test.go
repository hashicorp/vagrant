package state

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestBox(t *testing.T) {
	t.Run("Get returns error if not exist", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		_, err := s.BoxGet(&vagrant_plugin_sdk.Ref_Box{ResourceId: "nothing"})
		require.Error(err)
	})

	t.Run("Put and Get", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBox := &vagrant_server.Box{
			Id:       "qwerwasdf",
			Name:     "hashicorp/bionic",
			Version:  "1.2.3",
			Provider: "virtualbox",
		}

		testBoxRef := &vagrant_plugin_sdk.Ref_Box{
			ResourceId: "qwerwasdf",
			Name:       "hashicorp/bionic",
			Version:    "1.2.3",
			Provider:   "virtualbox",
		}

		// Set
		err := s.BoxPut(testBox)
		require.NoError(err)

		// Get full ref
		{
			resp, err := s.BoxGet(testBoxRef)
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBox.Name)
		}

		// Get by id
		{
			resp, err := s.BoxGet(&vagrant_plugin_sdk.Ref_Box{
				ResourceId: "qwerwasdf",
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBox.Name)
		}
	})

	t.Run("Delete", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		testBox := &vagrant_server.Box{
			Id:       "qwerwasdf",
			Name:     "hashicorp/bionic",
			Version:  "1.2.3",
			Provider: "virtualbox",
		}

		testBoxRef := &vagrant_plugin_sdk.Ref_Box{
			ResourceId: "qwerwasdf",
		}
		err := s.BoxDelete(testBoxRef)
		require.NoError(err)

		err = s.BoxPut(testBox)
		require.NoError(err)

		err = s.BoxDelete(testBoxRef)
		require.NoError(err)

		_, err = s.BoxGet(testBoxRef)
		require.Error(err)
	})

	t.Run("List", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		err := s.BoxPut(&vagrant_server.Box{
			Id:       "qwerwasdf",
			Name:     "hashicorp/bionic",
			Version:  "1.2.3",
			Provider: "virtualbox",
		})
		require.NoError(err)

		err = s.BoxPut(&vagrant_server.Box{
			Id:       "rrbrwasdf",
			Name:     "hashicorp/bionic",
			Version:  "1.2.4",
			Provider: "virtualbox",
		})
		require.NoError(err)

		b, err := s.BoxList()
		require.NoError(err)
		require.Len(b, 2)
	})
}
