package client

import (
	"context"
	"testing"

	"github.com/hashicorp/go-hclog"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/singleprocess"
)

func init() {
	hclog.L().SetLevel(hclog.Trace)
}

func TestProjectNoop(t *testing.T) {
	ctx := context.Background()
	require := require.New(t)
	client := singleprocess.TestServer(t)

	// Build our client
	c := TestProject(t, WithClient(client), WithLocal())
	app := c.App(TestApp(t, c))

	// TODO(mitchellh): once we have an API to list jobs, verify we have
	// no jobs, and then verify we execute a job after.

	// Noop
	require.NoError(app.Noop(ctx))
}
