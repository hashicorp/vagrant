package state

import (
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	serverptypes "github.com/hashicorp/vagrant/internal/server/ptypes"
	"gorm.io/gorm"
)

func TestProject_Create(t *testing.T) {
	t.Run("Requires name, path, and basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Project{})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
		require.ErrorContains(result.Error, "Path:")
		require.ErrorContains(result.Error, "Basis:")
	})

	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Project{
				Path:  "/dev/null",
				Basis: testBasis(t, db),
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Requires path", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Project{
				Name:  "default",
				Basis: testBasis(t, db),
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Requires basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Project{
				Name: "default",
				Path: "/dev/null",
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Basis:")
	})

	t.Run("Sets resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(&project)
		require.NoError(result.Error)
		require.NotEmpty(project.ResourceId)
	})

	t.Run("Retains resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		rid := "RESOURCE_ID"
		project := Project{
			Name:       "default",
			Path:       "/dev/null",
			ResourceId: rid,
			Basis:      testBasis(t, db),
		}
		result := db.Save(&project)
		require.NoError(result.Error)
		require.EqualValues(rid, project.ResourceId)
	})

	t.Run("Does not allow duplicate name in same basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := testBasis(t, db)
		result := db.Save(
			&Project{
				Name:  "default",
				Path:  "/dev/null",
				Basis: basis,
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Project{
				Name:  "default",
				Path:  "/dev/null/other",
				Basis: basis,
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Allows duplicate name in different basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Project{
				Name:  "default",
				Path:  "/dev/null",
				Basis: testBasis(t, db),
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Project{
				Name:  "default",
				Path:  "/dev/null/other",
				Basis: testBasis(t, db),
			},
		)
		require.NoError(result.Error)
	})

	t.Run("Does not allow duplicate path in same basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		basis := testBasis(t, db)
		result := db.Save(
			&Project{
				Name:  "default",
				Path:  "/dev/null",
				Basis: basis,
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Project{
				Name:  "other",
				Path:  "/dev/null",
				Basis: basis,
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Allows duplicate path in different basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Project{
				Name:  "default",
				Path:  "/dev/null",
				Basis: testBasis(t, db),
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Project{
				Name:  "other",
				Path:  "/dev/null",
				Basis: testBasis(t, db),
			},
		)
		require.NoError(result.Error)
	})

	t.Run("Does not allow duplicate resource IDs", func(t *testing.T) {
		require, db := requireAndDB(t)

		rid := "RESOURCE ID"
		result := db.Save(
			&Project{
				Name:       "default",
				Path:       "/dev/null",
				ResourceId: rid,
				Basis:      testBasis(t, db),
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Project{
				Name:       "other",
				Path:       "/dev/null/other",
				ResourceId: rid,
				Basis:      testBasis(t, db),
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "ResourceId:")
	})

	t.Run("Creates Vagrantfile when set", func(t *testing.T) {
		require, db := requireAndDB(t)

		vagrantfile := Vagrantfile{}
		project := Project{
			Name:        "default",
			Path:        "/dev/null",
			Basis:       testBasis(t, db),
			Vagrantfile: &vagrantfile,
		}
		result := db.Save(&project)
		require.NoError(result.Error)
		require.NotNil(project.VagrantfileID)
		require.Equal(*project.VagrantfileID, vagrantfile.ID)
	})
}

func TestProject_Update(t *testing.T) {
	t.Run("Requires name and path", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := &Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(project)
		require.NoError(result.Error)

		project.Name = ""
		project.Path = ""
		result = db.Save(project)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := &Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(project)
		require.NoError(result.Error)
		project.Name = ""
		result = db.Save(project)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Requires path", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := &Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(project)
		require.NoError(result.Error)
		project.Path = ""
		result = db.Save(project)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Path:")
	})

	t.Run("Requires basis", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := &Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(project)
		require.NoError(result.Error)
		project.Basis = nil
		project.BasisID = 0
		result = db.Save(project)
		require.Error(result.Error)
	})

	t.Run("Does not update resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(&project)
		require.NoError(result.Error)
		require.NotNil(project.ResourceId)
		require.NotEmpty(project.ResourceId)

		var reloadProject Project
		result = db.First(&reloadProject, &Project{Model: Model{ID: project.ID}})
		require.NoError(result.Error)

		reloadProject.ResourceId = "NEW VALUE"
		result = db.Save(&reloadProject)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "ResourceId:")
	})

	t.Run("Adds Vagrantfile", func(t *testing.T) {
		require, db := requireAndDB(t)

		vpath := "/dev/null/Vagrantfile"
		project := Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
		}
		result := db.Save(&project)
		require.NoError(result.Error)
		v := &Vagrantfile{Path: &vpath}
		project.Vagrantfile = v
		result = db.Save(&project)
		require.NoError(result.Error)
		require.NotEmpty(v.ID)
	})

	t.Run("Updates existing Vagrantfile content", func(t *testing.T) {
		require, db := requireAndDB(t)

		// Create inital basis
		vpath := "/dev/null/Vagrantfile"
		v := &Vagrantfile{Path: &vpath}
		project := Project{
			Name:        "default",
			Path:        "/dev/null",
			Vagrantfile: v,
			Basis:       testBasis(t, db),
		}
		result := db.Save(&project)
		require.NoError(result.Error)
		require.NotEmpty(v.ID)
		originalID := v.ID

		// Update with new Vagrantfile
		newPath := "/dev/null/new"
		newV := &Vagrantfile{Path: &newPath}
		project.Vagrantfile = newV
		result = db.Save(&project)
		require.NoError(result.Error)
		require.Equal(*project.Vagrantfile.Path, newPath)
		require.Equal(originalID, project.Vagrantfile.ID)

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

func TestProject_Delete(t *testing.T) {
	t.Run("Deletes project", func(t *testing.T) {
		require, db := requireAndDB(t)

		seedProject := testProject(t, db)

		var project Project
		result := db.First(&project,
			&Project{
				Name: seedProject.Name,
				Path: seedProject.Path,
			},
		)
		require.NoError(result.Error)

		result = db.Where(&Project{ResourceId: project.ResourceId}).
			Delete(&Project{})
		require.NoError(result.Error)
		result = db.First(&Project{}, &Project{ResourceId: project.ResourceId})
		require.Error(result.Error)
		require.ErrorIs(result.Error, gorm.ErrRecordNotFound)
	})

	t.Run("Deletes Vagrantfile", func(t *testing.T) {
		require, db := requireAndDB(t)

		vpath := "/dev/null/Vagrantfile"
		result := db.Save(&Project{
			Name:        "default",
			Path:        "/dev/null",
			Basis:       testBasis(t, db),
			Vagrantfile: &Vagrantfile{Path: &vpath},
		})
		require.NoError(result.Error)

		var count int64
		result = db.Model(&Vagrantfile{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(1), count)

		result = db.Where(&Project{Name: "default"}).
			Delete(&Basis{})
		require.NoError(result.Error)
		result = db.Model((*Vagrantfile)(nil)).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
	})

	t.Run("Deletes targets", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Project{
			Name:  "default",
			Path:  "/dev/null",
			Basis: testBasis(t, db),
			Targets: []*Target{
				{
					Name: "default",
				},
				{
					Name: "Other",
				},
			},
		})
		require.NoError(result.Error)

		var count int64
		result = db.Model(&Project{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(1), count)
		result = db.Model(&Target{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(2), count)

		result = db.Where(&Project{Name: "default"}).
			Delete(&Project{})
		require.NoError(result.Error)

		result = db.Model(&Project{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
		result = db.Model(&Target{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
	})
}

func TestProject_State(t *testing.T) {
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
		basisRef := testBasisProto(t, s)

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
		basisRef := testBasisProto(t, s)

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
