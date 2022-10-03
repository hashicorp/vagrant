package state

import (
	"testing"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"gorm.io/gorm"
)

func TestBasis_Create(t *testing.T) {
	t.Run("Requires name and path", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{Path: "/dev/null"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Requires path", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{Name: "default"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Sets resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := Basis{Name: "default", Path: "/dev/null"}
		result := db.Save(&basis)
		require.NoError(result.Error)
		require.NotEmpty(basis.ResourceId)
	})

	t.Run("Retains resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		rid := "RESOURCE_ID"
		basis := Basis{Name: "default", Path: "/dev/null", ResourceId: rid}
		result := db.Save(&basis)
		require.NoError(result.Error)
		require.EqualValues(rid, basis.ResourceId)
	})

	t.Run("Does not allow duplicate name", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{Name: "default", Path: "/dev/null"})
		require.NoError(result.Error)
		result = db.Save(&Basis{Name: "default", Path: "/dev/null/other"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Does not allow duplicate path", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{Name: "default", Path: "/dev/null"})
		require.NoError(result.Error)
		result = db.Save(&Basis{Name: "other", Path: "/dev/null"})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Does not allow duplicate resource IDs", func(t *testing.T) {
		require, db := requireAndDB(t)

		rid := "RESOURCE ID"
		result := db.Save(&Basis{Name: "default", Path: "/dev/null", ResourceId: rid})
		require.NoError(result.Error)
		result = db.Save(&Basis{Name: "other", Path: "/dev/null/other", ResourceId: rid})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "ResourceId:")
	})

	t.Run("Creates Vagrantfile when set", func(t *testing.T) {
		require, db := requireAndDB(t)

		vagrantfile := Vagrantfile{}
		basis := Basis{
			Name:        "default",
			Path:        "/dev/null",
			Vagrantfile: &vagrantfile,
		}
		result := db.Save(&basis)
		require.NoError(result.Error)
		require.NotNil(basis.VagrantfileID)
		require.Equal(*basis.VagrantfileID, vagrantfile.ID)
	})
}

func TestBasis_Update(t *testing.T) {
	t.Run("Requires name and path", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := &Basis{Name: "default", Path: "/dev/null"}
		result := db.Save(basis)
		require.NoError(result.Error)

		basis.Name = ""
		basis.Path = ""
		result = db.Save(basis)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := &Basis{Name: "default", Path: "/dev/null"}
		result := db.Save(basis)
		require.NoError(result.Error)
		basis.Name = ""
		result = db.Save(basis)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Requires path", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := &Basis{Name: "default", Path: "/dev/null"}
		result := db.Save(basis)
		require.NoError(result.Error)
		basis.Path = ""
		result = db.Save(basis)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Does not update resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := Basis{Name: "default", Path: "/dev/null"}
		result := db.Save(&basis)
		require.NoError(result.Error)
		require.NotEmpty(basis.ResourceId)

		var reloadBasis Basis
		result = db.First(&reloadBasis, &Basis{Model: Model{ID: basis.ID}})
		require.NoError(result.Error)

		reloadBasis.ResourceId = "NEW VALUE"
		result = db.Save(&reloadBasis)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "ResourceId:")
	})

	t.Run("Adds Vagrantfile", func(t *testing.T) {
		require, db := requireAndDB(t)

		vpath := "/dev/null/Vagrantfile"
		basis := Basis{Name: "default", Path: "/dev/null"}
		result := db.Save(&basis)
		require.NoError(result.Error)
		v := &Vagrantfile{Path: &vpath}
		basis.Vagrantfile = v
		result = db.Save(&basis)
		require.NoError(result.Error)
		require.NotEmpty(v.ID)
	})

	t.Run("Updates existing Vagrantfile content", func(t *testing.T) {
		require, db := requireAndDB(t)

		// Create inital basis
		vpath := "/dev/null/Vagrantfile"
		v := &Vagrantfile{Path: &vpath}
		basis := Basis{Name: "default", Path: "/dev/null", Vagrantfile: v}
		result := db.Save(&basis)
		require.NoError(result.Error)
		require.NotEmpty(v.ID)
		originalID := v.ID

		// Update with new Vagrantfile
		newPath := "/dev/null/new"
		newV := &Vagrantfile{Path: &newPath}
		basis.Vagrantfile = newV
		result = db.Save(&basis)
		require.NoError(result.Error)
		require.Equal(*basis.Vagrantfile.Path, newPath)
		require.Equal(originalID, basis.Vagrantfile.ID)

		// Refetch Vagrantfile to ensure persisted changes
		var checkVF Vagrantfile
		result = db.First(&checkVF, &Vagrantfile{Model: Model{ID: originalID}})
		require.NoError(result.Error)
		require.Equal(*checkVF.Path, newPath)

		// Validate only one Vagrantfile has been stored
		var count int64
		result = db.Model(&Vagrantfile{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(1), count)
	})
}

func TestBasis_Delete(t *testing.T) {
	t.Run("Deletes basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{Name: "default", Path: "/dev/null"})
		require.NoError(result.Error)

		var basis Basis
		result = db.First(&basis, &Basis{Name: "default"})
		require.NoError(result.Error)

		result = db.Where(&Basis{ResourceId: basis.ResourceId}).
			Delete(&Basis{})
		require.NoError(result.Error)
		result = db.First(&Basis{}, &Basis{ResourceId: basis.ResourceId})
		require.Error(result.Error)
		require.ErrorIs(result.Error, gorm.ErrRecordNotFound)
	})

	t.Run("Deletes Vagrantfile", func(t *testing.T) {
		require, db := requireAndDB(t)

		vpath := "/dev/null/Vagrantfile"
		result := db.Save(&Basis{
			Name:        "default",
			Path:        "/dev/null",
			Vagrantfile: &Vagrantfile{Path: &vpath},
		})
		require.NoError(result.Error)

		var count int64
		result = db.Model(&Vagrantfile{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(1), count)

		result = db.Where(&Basis{Name: "default"}).
			Delete(&Basis{})
		require.NoError(result.Error)
		result = db.Model((*Vagrantfile)(nil)).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
	})

	t.Run("Deletes Projects", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Basis{
			Name: "default",
			Path: "/dev/null",
			Projects: []*Project{
				{
					Name: "default",
					Path: "/dev/null/default",
				},
				{
					Name: "Other",
					Path: "/dev/null/other",
				},
			},
		})
		require.NoError(result.Error)

		var count int64
		result = db.Model(&Basis{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(1), count)
		result = db.Model(&Project{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(2), count)

		result = db.Where(&Basis{Name: "default"}).
			Delete(&Basis{})
		require.NoError(result.Error)

		result = db.Model(&Basis{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
		result = db.Model(&Project{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
	})
}

func TestBasis_State(t *testing.T) {
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
