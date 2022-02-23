package core

import (
	"context"

	"github.com/hashicorp/go-hclog"
	"github.com/mitchellh/go-testing-interface"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/plugin"
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

// // TestFactorySingle creates a factory for the given component type and
// // registers a single implementation and returns that mock. This is useful
// // to create a factory for the WithFactory option that returns a mocked value
// // that can be tested against.
// func TestFactorySingle(t testing.T, typ component.Type, n string) (*factory.Factory, *mock.Mock) {
// 	f := TestFactory(t, typ)
// 	c := componentmocks.ForType(typ)
// 	require.NotNil(t, c)
// 	TestFactoryRegister(t, f, n, c)

// 	return f, componentmocks.Mock(c)
// }

// // TestFactory creates a factory for the given component type.
// func TestFactory(t testing.T, typ component.Type) *factory.Factory {
// 	f, err := factory.New(component.TypeMap[typ])
// 	require.NoError(t, err)
// 	return f
// }

// // TestFactoryRegister registers a singleton value to be returned for the
// // factory for the name n.
// func TestFactoryRegister(t testing.T, f *factory.Factory, n string, v interface{}) {
// 	require.NoError(t, f.Register(n, func() interface{} { return v }))
// }
