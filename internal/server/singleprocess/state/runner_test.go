package state

import (
	"testing"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestRunner(t *testing.T) {
	t.Run("Basic CRUD", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		// Create an instance
		rec := &vagrant_server.Runner{Id: "A"}
		require.NoError(s.RunnerCreate(rec))

		// We should be able to find it
		found, err := s.RunnerById(rec.Id)
		require.NoError(err)
		require.Equal(rec.Id, found.Id)
		require.Empty(found.Components)

		// Delete that instance
		require.NoError(s.RunnerDelete(rec.Id))

		// We should not find it
		found, err = s.RunnerById(rec.Id)
		require.Error(err)
		require.Nil(found)
		require.Equal(codes.NotFound, status.Code(err))

		// Delete again should be fine
		require.NoError(s.RunnerDelete(rec.Id))
	})

	t.Run("CRUD with components", func(t *testing.T) {
		require := require.New(t)

		s := TestState(t)
		defer s.Close()

		components := []*vagrant_server.Component{
			{
				Name: "command",
				Type: vagrant_server.Component_COMMAND,
			},
			{
				Name: "communicator",
				Type: vagrant_server.Component_COMMUNICATOR,
			},
		}

		// Create an instance
		rec := &vagrant_server.Runner{
			Id:         "A",
			Components: components,
		}
		require.NoError(s.RunnerCreate(rec))

		found, err := s.RunnerById(rec.Id)
		require.NoError(err)
		require.Equal(rec.Id, found.Id)
		require.Equal(rec.Components, found.Components)
	})
}

func TestRunnerById_notFound(t *testing.T) {
	require := require.New(t)

	s := TestState(t)
	defer s.Close()

	// We should be able to find it
	found, err := s.RunnerById("nope")
	require.Error(err)
	require.Nil(found)
	require.Equal(codes.NotFound, status.Code(err))
}
