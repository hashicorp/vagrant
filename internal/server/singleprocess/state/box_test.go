package state

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
)

func TestBox_Create(t *testing.T) {
	t.Run("Requires directory, name, provider", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Directory:")
		require.ErrorContains(result.Error, "Name:")
		require.ErrorContains(result.Error, "Provider:")
	})

	t.Run("Requires directory", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{Name: "default", Provider: "virt"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Directory:")
	})

	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{Provider: "virt", Directory: "/dev/null"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Requires provider", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{Name: "default", Directory: "/dev/null"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Provider:")
	})

	t.Run("Sets the ResourceId", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
		})
		require.NoError(result.Error)
		var box Box
		result = db.First(&box, &Box{Name: "default"})
		require.NoError(result.Error)
		require.NotEmpty(box.ResourceId)
	})

	t.Run("Defaults version when not set", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
		})
		require.NoError(result.Error)
		var box Box
		result = db.First(&box, &Box{Name: "default"})
		require.NoError(result.Error)
		require.Equal(DEFAULT_BOX_VERSION, box.Version)
	})

	t.Run("Defaults version when set to 0", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
			Version:   "0",
		})
		require.NoError(result.Error)
		var box Box
		result = db.First(&box, &Box{Name: "default"})
		require.NoError(result.Error)
		require.Equal(DEFAULT_BOX_VERSION, box.Version)
	})

	t.Run("Requires version to be semver", func(t *testing.T) {
		require, db := requireAndDB(t)

		box := &Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
			Version:   "0.a",
		}

		result := db.Save(box)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Version:")

		box.Version = "string"
		result = db.Save(box)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Version:")

		box.Version = "a0.1.2"
		result = db.Save(box)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Version:")
	})

	t.Run("Does not allow duplicates", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
			Version:   "1.0.0",
		})
		require.NoError(result.Error)

		result = db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null/other",
			Provider:  "virt",
			Version:   "1.0.0",
		})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "name")
		require.ErrorContains(result.Error, "provider")
		require.ErrorContains(result.Error, "version")
	})

	t.Run("Allows multiple versions", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
			Version:   "1.0.0",
		})
		require.NoError(result.Error)

		result = db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null/other",
			Provider:  "virt",
			Version:   "1.0.1",
		})
		require.NoError(result.Error)
	})

	t.Run("Allows multiple providers", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null",
			Provider:  "virt",
			Version:   "1.0.0",
		})
		require.NoError(result.Error)

		result = db.Save(&Box{
			Name:      "default",
			Directory: "/dev/null/other",
			Provider:  "virtz",
			Version:   "1.0.0",
		})
		require.NoError(result.Error)
	})
}

func TestBox_State(t *testing.T) {
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
			ResourceId: "qwerwasdf",
			Directory:  "/directory",
			Name:       "hashicorp/bionic",
			Version:    "1.2.3",
			Provider:   "virtualbox",
		}

		testBox2 := &vagrant_server.Box{
			ResourceId: "qwerwasdf-2",
			Directory:  "/directory-2",
			Name:       "hashicorp/bionic",
			Version:    "1.2.4",
			Provider:   "virtualbox",
		}

		testBoxRef := &vagrant_plugin_sdk.Ref_Box{
			ResourceId: "qwerwasdf",
			Name:       "hashicorp/bionic",
			Version:    "1.2.3",
			Provider:   "virtualbox",
		}

		testBoxRef2 := &vagrant_plugin_sdk.Ref_Box{
			ResourceId: "qwerwasdf-2",
			Name:       "hashicorp/bionic",
			Version:    "1.2.4",
			Provider:   "virtualbox",
		}

		// Set
		err := s.BoxPut(testBox)
		require.NoError(err)
		err = s.BoxPut(testBox2)
		require.NoError(err)

		// Get full ref
		{
			resp, err := s.BoxGet(testBoxRef)
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBox.Name)

			resp, err = s.BoxGet(testBoxRef2)
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.Name, testBox2.Name)
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
			ResourceId: "qwerwasdf",
			Directory:  "/directory",
			Name:       "hashicorp/bionic",
			Version:    "1.2.3",
			Provider:   "virtualbox",
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
			ResourceId: "qwerwasdf",
			Directory:  "/directory",
			Name:       "hashicorp/bionic",
			Version:    "1.2.3",
			Provider:   "virtualbox",
		})
		require.NoError(err)

		err = s.BoxPut(&vagrant_server.Box{
			ResourceId: "rrbrwasdf",
			Directory:  "/other-directory",
			Name:       "hashicorp/bionic",
			Version:    "1.2.4",
			Provider:   "virtualbox",
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
			ResourceId: "hashicorp/bionic-1.2.3-virtualbox",
			Directory:  "/directory",
			Name:       "hashicorp/bionic",
			Version:    "1.2.3",
			Provider:   "virtualbox",
		})
		require.NoError(err)

		err = s.BoxPut(&vagrant_server.Box{
			ResourceId: "hashicorp/bionic-1.2.4-virtualbox",
			Directory:  "/other-directory",
			Name:       "hashicorp/bionic",
			Version:    "1.2.4",
			Provider:   "virtualbox",
		})
		require.NoError(err)

		err = s.BoxPut(&vagrant_server.Box{
			ResourceId: "box-0-virtualbox",
			Directory:  "/another-directory",
			Name:       "box",
			Version:    "0",
			Provider:   "virtualbox",
		})
		require.NoError(err)

		b, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "hashicorp/bionic",
			Provider: "virtualbox",
		})
		require.NoError(err)
		require.Equal(b.Name, "hashicorp/bionic")
		require.Equal(b.Version, "1.2.4")

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
		require.Error(err)
		require.Nil(b6)

		b7, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name: "dontexist",
		})
		require.Error(err)
		require.Nil(b7)

		b8, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "hashicorp/bionic",
			Provider: "virtualbox",
			Version:  "~> 1.2",
		})
		require.NoError(err)
		require.Equal(b8.Name, "hashicorp/bionic")
		require.Equal(b8.Version, "1.2.4")

		b9, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "hashicorp/bionic",
			Provider: "virtualbox",
			Version:  "> 1.0, < 3.0",
		})
		require.NoError(err)
		require.Equal(b9.Name, "hashicorp/bionic")
		require.Equal(b9.Version, "1.2.4")

		b10, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:    "hashicorp/bionic",
			Version: "< 1.0",
		})
		require.Error(err)
		require.Nil(b10)

		b11, err := s.BoxFind(&vagrant_plugin_sdk.Ref_Box{
			Name:     "box",
			Version:  "0",
			Provider: "virtualbox",
		})
		require.NoError(err)
		require.Equal(b11.Name, "box")
		require.Equal(b11.Version, "0.0.0")
	})
}
