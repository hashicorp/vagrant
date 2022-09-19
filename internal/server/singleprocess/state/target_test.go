package state

import (
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/anypb"
	"google.golang.org/protobuf/types/known/wrapperspb"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
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
		require.Error(err)

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
		projectRef := testProject(t, s)

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
		projectRef := testProject(t, s)

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
