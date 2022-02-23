package core

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"
)

func TestBasis(t testing.T, opts ...BasisOption) (b *Basis) {
	td, err := ioutil.TempDir("", "core")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	projDir, err := datadir.NewBasis(td)
	require.NoError(t, err)

	defaultOpts := []BasisOption{
		WithClient(singleprocess.TestServer(t)),
		WithBasisDataDir(projDir),
		WithBasisRef(&vagrant_plugin_sdk.Ref_Basis{Name: "test-basis"}),
	}

	b, _ = NewBasis(context.Background(), append(defaultOpts, opts...)...)
	return
}
