package ptypes

import (
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

func TestRunner(t testing.T, src *vagrant_server.Runner) *vagrant_server.Runner {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Runner{}
	}

	id, err := server.Id()
	require.NoError(t, err)

	require.NoError(t, mergo.Merge(src, &vagrant_server.Runner{
		Id: id,
	}))

	return src
}
