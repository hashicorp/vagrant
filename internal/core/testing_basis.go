package core

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/hashicorp/vagrant-plugin-sdk/core"
	coremocks "github.com/hashicorp/vagrant-plugin-sdk/core/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"
)

type PluginWithParent struct {
	parentPlugin interface{}
}

func (p *PluginWithParent) GetParentComponent() interface{} {
	return p.parentPlugin
}
func (p *PluginWithParent) SetParentComponent(in interface{}) {
	p.parentPlugin = in
}

type TestGuestPlugin struct {
	PluginWithParent
	plugin.TestPluginWithFakeBroker
	coremocks.Guest
}

type TestHostPlugin struct {
	PluginWithParent
	plugin.TestPluginWithFakeBroker
	coremocks.Host
}

type TestSyncedFolderPlugin struct {
	PluginWithParent
	plugin.TestPluginWithFakeBroker
	coremocks.SyncedFolder
}

func BuildTestGuestPlugin(name string, parent string) *TestGuestPlugin {
	p := &TestGuestPlugin{}
	p.On("SetPluginName", mock.AnythingOfType("string")).Return(nil)
	p.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	p.On("Seeds").Return(core.NewSeeds(), nil)
	p.On("PluginName").Return(name, nil)
	p.On("Parent").Return(parent, nil)
	return p
}

func BuildTestHostPlugin(name string, parent string) *TestHostPlugin {
	p := &TestHostPlugin{}
	p.On("SetPluginName", mock.AnythingOfType("string")).Return(nil)
	p.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	p.On("Seeds").Return(core.NewSeeds(), nil)
	p.On("PluginName").Return(name, nil)
	p.On("Parent").Return(parent, nil)
	return p
}

func BuildTestSyncedFolderPlugin(parent string) *TestSyncedFolderPlugin {
	p := &TestSyncedFolderPlugin{}
	p.On("SetPluginName", mock.AnythingOfType("string")).Return(nil)
	p.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	p.On("Seeds").Return(core.NewSeeds(), nil)
	p.On("Parent").Return(parent, nil)
	return p
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
