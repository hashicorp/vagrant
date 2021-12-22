package core

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/hashicorp/go-hclog"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	componentmocks "github.com/hashicorp/vagrant-plugin-sdk/component/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/core"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/factory"
	"github.com/hashicorp/vagrant/internal/plugin"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
)

var TestingTypeMap = map[component.Type]interface{}{
	component.CommandType:      (*component.Command)(nil),
	component.CommunicatorType: (*component.Communicator)(nil),
	component.ConfigType:       (*component.Config)(nil),
	component.GuestType:        (*component.Guest)(nil),
	component.HostType:         (*component.Host)(nil),
	component.LogPlatformType:  (*component.LogPlatform)(nil),
	component.LogViewerType:    (*component.LogViewer)(nil),
	component.ProviderType:     (*component.Provider)(nil),
	component.ProvisionerType:  (*component.Provisioner)(nil),
	component.SyncedFolderType: (*component.SyncedFolder)(nil),
}

// TestTarget returns a fully in-memory and side-effect free Target that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestTarget(t testing.T, opts ...BasisOption) (target *Target, err error) {
	tp := TestProject(t, opts...)
	tp.basis.client.UpsertTarget(
		context.Background(),
		&vagrant_server.UpsertTargetRequest{
			Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
			Target: &vagrant_server.Target{
				Name:    "test-target",
				Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project),
			},
		},
	)
	target, err = tp.LoadTarget([]TargetOption{
		WithTargetRef(&vagrant_plugin_sdk.Ref_Target{Project: tp.Ref().(*vagrant_plugin_sdk.Ref_Project), Name: "test-target"}),
	}...)

	return
}

// TestMachine returns a fully in-memory and side-effect free Machine that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestMachine(t testing.T, opts ...BasisOption) (machine *Machine, err error) {
	tt, _ := TestTarget(t)
	specialized, err := tt.Specialize((*core.Machine)(nil))
	if err != nil {
		return nil, err
	}
	machine = specialized.(*Machine)
	return
}

// TestProject returns a fully in-memory and side-effect free Project that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestProject(t testing.T, opts ...BasisOption) *Project {
	pluginManager := plugin.NewManager(
		context.Background(),
		hclog.New(&hclog.LoggerOptions{}),
	)

	opts = append(opts, WithPluginManager(pluginManager))
	b := TestBasis(t, opts...)

	p, _ := b.LoadProject([]ProjectOption{
		WithProjectRef(&vagrant_plugin_sdk.Ref_Project{
			Basis: b.Ref().(*vagrant_plugin_sdk.Ref_Basis),
			Name:  "test-project"},
		),
	}...)
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

// TestFactorySingle creates a factory for the given component type and
// registers a single implementation and returns that mock. This is useful
// to create a factory for the WithFactory option that returns a mocked value
// that can be tested against.
func TestFactorySingle(t testing.T, typ component.Type, n string) (*factory.Factory, *mock.Mock) {
	f := TestFactory(t, typ)
	c := componentmocks.ForType(typ)
	require.NotNil(t, c)
	TestFactoryRegister(t, f, n, c)

	return f, componentmocks.Mock(c)
}

// TestFactory creates a factory for the given component type.
func TestFactory(t testing.T, typ component.Type) *factory.Factory {
	f, err := factory.New(component.TypeMap[typ])
	require.NoError(t, err)
	return f
}

// TestFactoryRegister registers a singleton value to be returned for the
// factory for the name n.
func TestFactoryRegister(t testing.T, f *factory.Factory, n string, v interface{}) {
	require.NoError(t, f.Register(n, func() interface{} { return v }))
}
