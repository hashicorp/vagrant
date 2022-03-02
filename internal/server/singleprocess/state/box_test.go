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

	t.Run("Find", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		err := s.BoxPut(&vagrant_server.Box{
			Id:       "hashicorp/bionic-1.2.3-virtualbox",
			Name:     "hashicorp/bionic",
			Version:  "1.2.3",
			Provider: "virtualbox",
		})
		require.NoError(err)

		err = s.BoxPut(&vagrant_server.Box{
			Id:       "hashicorp/bionic-1.2.4-virtualbox",
			Name:     "hashicorp/bionic",
			Version:  "1.2.4",
			Provider: "virtualbox",
		})
		require.NoError(err)

		err = s.BoxPut(&vagrant_server.Box{
			Id:       "box-0-virtualbox",
			Name:     "box",
			Version:  "0",
			Provider: "virtualbox",
		})
		require.NoError(err)

		b, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name: "hashicorp/bionic",
		})
		require.NoError(err)
		require.Equal(b.Name, "hashicorp/bionic")
		require.Equal(b.Version, "1.2.4")

		b2, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:    "hashicorp/bionic",
			Version: "1.2.3",
		})
		require.NoError(err)
		require.Equal(b2.Name, "hashicorp/bionic")
		require.Equal(b2.Version, "1.2.3")

		b3, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "hashicorp/bionic",
			Version:  "1.2.3",
			Provider: "virtualbox",
		})
		require.NoError(err)
		require.Equal(b3.Name, "hashicorp/bionic")
		require.Equal(b3.Version, "1.2.3")
		require.Equal(b3.Provider, "virtualbox")

		b4, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "hashicorp/bionic",
			Version:  "1.2.3",
			Provider: "dontexist",
		})
		require.NoError(err)
		require.Nil(b4)

		b5, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "hashicorp/bionic",
			Version:  "9.9.9",
			Provider: "virtualbox",
		})
		require.NoError(err)
		require.Nil(b5)

		b6, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Version: "1.2.3",
		})
		require.NoError(err)
		require.Nil(b6)

		b7, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name: "dontexist",
		})
		require.NoError(err)
		require.Nil(b7)

		b8, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:    "hashicorp/bionic",
			Version: "~> 1.2",
		})
		require.NoError(err)
		require.Equal(b8.Name, "hashicorp/bionic")
		require.Equal(b8.Version, "1.2.4")

		b9, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:    "hashicorp/bionic",
			Version: "> 1.0, < 3.0",
		})
		require.NoError(err)
		require.Equal(b9.Name, "hashicorp/bionic")
		require.Equal(b9.Version, "1.2.4")

		b10, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:    "hashicorp/bionic",
			Version: "< 1.0",
		})
		require.NoError(err)
		require.Nil(b10)

		b11, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:    "box",
			Version: "0",
		})
		require.NoError(err)
		require.Equal(b11.Name, "box")
		require.Equal(b11.Version, "0")
	})
}
