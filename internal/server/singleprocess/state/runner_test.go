package state

import (
	"testing"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

func TestRunner_crud(t *testing.T) {
	require := require.New(t)

	s := TestState(t)
	defer s.Close()

	// Create an instance
	rec := &vagrant_server.Runner{Id: "A"}
	require.NoError(s.RunnerCreate(rec))

	// We should be able to find it
	found, err := s.RunnerById(rec.Id)
	require.NoError(err)
	require.Equal(rec, found)

	// Delete that instance
	require.NoError(s.RunnerDelete(rec.Id))

	// We should not find it
	found, err = s.RunnerById(rec.Id)
	require.Error(err)
	require.Nil(found)
	require.Equal(codes.NotFound, status.Code(err))

	// Delete again should be fine
	require.NoError(s.RunnerDelete(rec.Id))
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
