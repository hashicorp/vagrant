package core

import (
	"context"
	"io/ioutil"
	"os"
	"path/filepath"

	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	coremocks "github.com/hashicorp/vagrant-plugin-sdk/core/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant-plugin-sdk/terminal"
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

type TestCommunicatorPlugin struct {
	plugin.TestPluginWithFakeBroker
	coremocks.Communicator
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

func BuildTestCommunicatorPlugin(name string) *TestCommunicatorPlugin {
	c := &TestCommunicatorPlugin{}
	c.On("Seed", mock.AnythingOfType("*core.Seeds")).Return(nil)
	c.On("Seeds").Return(core.NewSeeds(), nil)
	c.On("PluginName").Return(name, nil)
	return c
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
	p.On("Usable", mock.AnythingOfType("*core.Machine")).Return(true, nil)
	return p
}

func TestBasis(t testing.T, opts ...BasisOption) (b *Basis) {
	td, err := ioutil.TempDir("", "core")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })
	name := filepath.Base(td)

	mkSubdir := func(root, sub string) string {
		sd := filepath.Join(root, sub)
		require.NoError(t, os.Mkdir(sd, 0755))
		return sd
	}

	projDir := &datadir.Basis{
		Dir: datadir.NewBasicDir(
			mkSubdir(td, "config"),
			mkSubdir(td, "cache"),
			mkSubdir(td, "data"),
			mkSubdir(td, "temp"),
		),
	}

	client := singleprocess.TestServer(t)
	manager := plugin.TestManager(t)

	factory := NewFactory(
		context.Background(),
		client,
		hclog.New(
			&hclog.LoggerOptions{
				Name:  "vagrant.core.factory",
				Level: hclog.Trace,
			},
		),
		manager,
		(terminal.UI)(nil),
	)

	defaultOpts := []BasisOption{
		WithFactory(factory),
		WithClient(client),
		WithBasisDataDir(projDir),
		WithBasisRef(&vagrant_plugin_sdk.Ref_Basis{Name: name, Path: td}),
	}

	b, err = factory.NewBasis("", append(defaultOpts, opts...)...)
	require.NoError(t, err)

	require.NoError(t, b.Save())
	return
}
