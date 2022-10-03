package state

import (
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/anypb"
	"google.golang.org/protobuf/types/known/wrapperspb"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestTarget_Create(t *testing.T) {
	t.Run("Requires name and project", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Target{})
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
		require.ErrorContains(result.Error, "Project:")
	})

	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Target{
				Project: testProject(t, db),
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Requires project", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Target{
				Name: "default",
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Project:")
	})

	t.Run("Sets resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		target := Target{
			Name:    "default",
			Project: testProject(t, db),
		}
		result := db.Save(&target)
		require.NoError(result.Error)
		require.NotEmpty(target.ResourceId)
	})

	t.Run("Retains resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		rid := "RESOURCE_ID"
		target := Target{
			Name:       "default",
			ResourceId: rid,
			Project:    testProject(t, db),
		}
		result := db.Save(&target)
		require.NoError(result.Error)
		require.NotNil(target.ResourceId)
		require.EqualValues(rid, target.ResourceId)
	})

	t.Run("Does not allow duplicate name in same project", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := testProject(t, db)
		result := db.Save(
			&Target{
				Name:    "default",
				Project: project,
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Target{
				Name:    "default",
				Project: project,
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Allows duplicate name in different projects", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(
			&Target{
				Name:    "default",
				Project: testProject(t, db),
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Target{
				Name:    "default",
				Project: testProject(t, db),
			},
		)
		require.NoError(result.Error)
	})

	t.Run("Does not allow duplicate resource IDs", func(t *testing.T) {
		require, db := requireAndDB(t)

		rid := "RESOURCE ID"
		result := db.Save(
			&Target{
				Name:       "default",
				ResourceId: rid,
				Project:    testProject(t, db),
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Target{
				Name:       "other",
				ResourceId: rid,
				Project:    testProject(t, db),
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "ResourceId:")
	})

	t.Run("Does not allow duplicate UUIDs", func(t *testing.T) {
		require, db := requireAndDB(t)

		uuid := "UUID VALUE"
		result := db.Save(
			&Target{
				Name:    "default",
				Uuid:    &uuid,
				Project: testProject(t, db),
			},
		)
		require.NoError(result.Error)
		result = db.Save(
			&Target{
				Name:    "other",
				Uuid:    &uuid,
				Project: testProject(t, db),
			},
		)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Uuid:")
	})

	t.Run("Stores a record when set", func(t *testing.T) {
		require, db := requireAndDB(t)

		record := &vagrant_server.Target_Machine{
			Id: "MACHINE_ID",
		}
		result := db.Save(
			&Target{
				Name:    "default",
				Project: testProject(t, db),
				Record:  &ProtoValue{Message: record},
			},
		)
		require.NoError(result.Error)
		var target Target
		result = db.First(&target, &Target{Name: "default"})
		require.NoError(result.Error)
		require.Equal(record.Id, target.Record.Message.(*vagrant_server.Target_Machine).Id)
	})

	t.Run("Properly creates child targets", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := testProject(t, db)
		result := db.Save(
			&Target{
				Name:    "parent",
				Project: project,
				Subtargets: []*Target{
					{
						Name:    "subtarget1",
						Project: project,
					},
					{
						Name:    "subtarget2",
						Project: project,
					},
					{
						Name:    "subtarget3",
						Project: project,
					},
				},
			},
		)
		require.NoError(result.Error)
		var target Target
		result = db.Preload(clause.Associations).
			First(&target, &Target{Name: "parent"})
		require.NoError(result.Error)
		require.Equal(3, len(target.Subtargets))
	})
}

func TestTarget_Update(t *testing.T) {
	t.Run("Requires name", func(t *testing.T) {
		require, db := requireAndDB(t)

		target := &Target{Name: "default", Project: testProject(t, db)}
		result := db.Save(target)
		require.NoError(result.Error)

		target.Name = ""
		result = db.Save(target)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "Name:")
	})

	t.Run("Does not update resource ID", func(t *testing.T) {
		require, db := requireAndDB(t)

		target := Target{Name: "default", Project: testProject(t, db)}
		result := db.Save(&target)
		require.NoError(result.Error)
		require.NotEmpty(target.ResourceId)

		var reloadTarget Basis
		result = db.First(&reloadTarget, &Target{Model: Model{ID: target.ID}})
		require.NoError(result.Error)

		reloadTarget.ResourceId = "NEW VALUE"
		result = db.Save(&reloadTarget)
		require.Error(result.Error)
		require.ErrorContains(result.Error, "ResourceId:")
	})

	t.Run("Adds subtarget", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := testProject(t, db)
		target := Target{
			Name:    "parent",
			Project: project,
			Subtargets: []*Target{
				{
					Name:    "subtarget1",
					Project: project,
				},
			},
		}
		result := db.Save(&target)
		require.NoError(result.Error)
		result = db.Preload(clause.Associations).First(&target, &Target{Name: "parent"})
		require.NoError(result.Error)
		require.Equal(1, len(target.Subtargets))
		target.Subtargets = append(target.Subtargets, &Target{
			Name:    "subtarget2",
			Project: project,
		})
		result = db.Save(&target)
		require.NoError(result.Error)
		result = db.Preload(clause.Associations).First(&target, &Target{Name: "parent"})
		require.NoError(result.Error)
		require.Equal(2, len(target.Subtargets))
	})

	t.Run("It fails to add subtarget with different project", func(t *testing.T) {
		require, db := requireAndDB(t)

		target := Target{
			Name:    "parent",
			Project: testProject(t, db),
		}
		result := db.Save(&target)
		require.NoError(result.Error)
		result = db.First(&target, &Target{Name: "parent"})
		require.NoError(result.Error)
		target.Subtargets = append(target.Subtargets, &Target{
			Name:    "subtarget",
			Project: testProject(t, db),
		})
		result = db.Save(&target)
		require.Error(result.Error)
	})
}

func TestTarget_Delete(t *testing.T) {
	t.Run("Deletes target", func(t *testing.T) {
		require, db := requireAndDB(t)

		result := db.Save(&Target{Name: "default", Project: testProject(t, db)})
		require.NoError(result.Error)

		var target Target
		result = db.First(&target, &Target{Name: "default"})
		require.NoError(result.Error)

		result = db.Where(&Target{ResourceId: target.ResourceId}).
			Delete(&Target{})
		require.NoError(result.Error)
		result = db.First(&Target{}, &Target{ResourceId: target.ResourceId})
		require.Error(result.Error)
		require.ErrorIs(result.Error, gorm.ErrRecordNotFound)
	})

	t.Run("Deletes subtargets", func(t *testing.T) {
		require, db := requireAndDB(t)

		project := testProject(t, db)
		result := db.Save(
			&Target{
				Name:    "parent",
				Project: project,
				Subtargets: []*Target{
					{
						Name:    "subtarget1",
						Project: project,
					},
					{
						Name:    "subtarget2",
						Project: project,
					},
				},
			},
		)
		require.NoError(result.Error)

		var count int64
		result = db.Model(&Target{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(3), count)

		result = db.Where(&Target{Name: "parent"}).
			Delete(&Target{})
		require.NoError(result.Error)
		result = db.Model(&Target{}).Count(&count)
		require.NoError(result.Error)
		require.Equal(int64(0), count)
	})
}

func TestTarget_State(t *testing.T) {
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
		projectRef := testProjectProto(t, s)

		// Set
		result, err := s.TargetPut(&vagrant_server.Target{
			Project: projectRef,
			Name:    "test",
		})
		require.NoError(err)

		// Ensure there is one entry
		resp, err := s.TargetList()
		require.NoError(err)
		require.Len(resp, 1)

		// Try to insert duplicate entry
		doubleResult, err := s.TargetPut(&vagrant_server.Target{
			ResourceId: result.ResourceId,
			Project:    projectRef,
			Name:       "test",
		})
		require.NoError(err)
		require.Equal(doubleResult.ResourceId, result.ResourceId)
		require.Equal(doubleResult.Project, result.Project)

		// Ensure there is still one entry
		resp, err = s.TargetList()
		require.NoError(err)
		require.Len(resp, 1)

		// Try to insert duplicate entry by just name and project
		_, err = s.TargetPut(&vagrant_server.Target{
			Project: projectRef,
			Name:    "test",
		})
		require.NoError(err)

		// Ensure there is still one entry
		resp, err = s.TargetList()
		require.NoError(err)
		require.Len(resp, 1)

		// Try to insert duplicate config
		key, _ := anypb.New(&wrapperspb.StringValue{Value: "vm"})
		value, _ := anypb.New(&wrapperspb.StringValue{Value: "value"})
		_, err = s.TargetPut(&vagrant_server.Target{
			ResourceId: result.ResourceId,
			Configuration: &vagrant_plugin_sdk.Args_ConfigData{
				Data: &vagrant_plugin_sdk.Args_Hash{
					Entries: []*vagrant_plugin_sdk.Args_HashEntry{
						{
							Key:   key,
							Value: value,
						},
					},
				},
			},
		})
		require.NoError(err)
		_, err = s.TargetPut(&vagrant_server.Target{
			ResourceId: result.ResourceId,
			Configuration: &vagrant_plugin_sdk.Args_ConfigData{
				Data: &vagrant_plugin_sdk.Args_Hash{
					Entries: []*vagrant_plugin_sdk.Args_HashEntry{
						{
							Key:   key,
							Value: value,
						},
					},
				},
			},
		})
		require.NoError(err)

		// Ensure there is still one entry
		resp, err = s.TargetList()
		require.NoError(err)
		require.Len(resp, 1)
		// Ensure the config did not merge
		targetResp, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
			ResourceId: result.ResourceId,
		})
		require.NoError(err)
		require.NotNil(targetResp.Configuration)
		require.NotNil(targetResp.Configuration.Data)
		require.Len(targetResp.Configuration.Data.Entries, 1)
		vmAny := targetResp.Configuration.Data.Entries[0].Value
		vmString := wrapperspb.StringValue{}
		_ = vmAny.UnmarshalTo(&vmString)
		require.Equal(vmString.Value, "value")

		// Get exact
		{
			resp, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
				ResourceId: result.ResourceId,
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.ResourceId, result.ResourceId)

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
		projectRef := testProjectProto(t, s)

		// Set
		result, err := s.TargetPut(&vagrant_server.Target{
			Project: projectRef,
			Name:    "test",
		})
		require.NoError(err)

		// Read
		resp, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
			ResourceId: result.ResourceId,
		})
		require.NoError(err)
		require.NotNil(resp)

		// Delete
		{
			err := s.TargetDelete(&vagrant_plugin_sdk.Ref_Target{
				ResourceId: result.ResourceId,
				Project:    projectRef,
			})
			require.NoError(err)
		}

		// Read
		{
			_, err := s.TargetGet(&vagrant_plugin_sdk.Ref_Target{
				ResourceId: result.ResourceId,
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

	t.Run("Find", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()
		projectRef := testProjectProto(t, s)

		// Set
		result, err := s.TargetPut(&vagrant_server.Target{
			Project: projectRef,
			Name:    "test",
		})
		require.NoError(err)

		// Find by resource id
		{
			resp, err := s.TargetFind(&vagrant_server.Target{
				ResourceId: result.ResourceId,
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.ResourceId, result.ResourceId)
		}

		// Find by resource name without project
		{
			resp, err := s.TargetFind(&vagrant_server.Target{
				Name: "test",
			})
			require.Error(err)
			require.Nil(resp)
		}

		// Find by resource name+project
		{
			resp, err := s.TargetFind(&vagrant_server.Target{
				Name: "test", Project: projectRef,
			})
			require.NoError(err)
			require.NotNil(resp)
			require.Equal(resp.ResourceId, result.ResourceId)
		}

		// Don't find nonexistent project
		{
			resp, err := s.TargetFind(&vagrant_server.Target{
				Name: "test", Project: &vagrant_plugin_sdk.Ref_Project{ResourceId: "idontexist"},
			})
			require.Nil(resp)
			require.Error(err)
		}

		// Don't find just by project
		{
			resp, err := s.TargetFind(&vagrant_server.Target{
				Project: projectRef,
			})
			require.Error(err)
			require.Nil(resp)
		}
	})
}
