package core

import (
	"context"
	"io/ioutil"
	"os"

	sdkcore "github.com/hashicorp/vagrant-plugin-sdk/core"
	coremocks "github.com/hashicorp/vagrant-plugin-sdk/core/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

func seededHostMock(name string) *coremocks.Host {
	guestMock := &coremocks.Host{}
	guestMock.On("Seeds").Return(sdkcore.NewSeeds(), nil)
	guestMock.On("Seed", mock.AnythingOfType("")).Return(nil)
	guestMock.On("PluginName").Return(name, nil)
	return guestMock
}

func seededGuestMock(name string) *coremocks.Guest {
	guestMock := &coremocks.Guest{}
	guestMock.On("Seeds").Return(sdkcore.NewSeeds(), nil)
	guestMock.On("Seed", mock.AnythingOfType("")).Return(nil)
	guestMock.On("PluginName").Return(name, nil)
	return guestMock
}

func seededSyncedFolderMock(name string) *coremocks.SyncedFolder {
	guestMock := &coremocks.SyncedFolder{}
	guestMock.On("Seeds").Return(sdkcore.NewSeeds(), nil)
	guestMock.On("Seed", mock.AnythingOfType("")).Return(nil)
	return guestMock
}

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

func WithTestBasisConfig(config *vagrant_plugin_sdk.Vagrantfile_Vagrantfile) BasisOption {
	return func(m *Basis) (err error) {
		m.basis.Configuration = config
		return
	}
}
