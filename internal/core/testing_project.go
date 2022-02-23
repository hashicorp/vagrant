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
	b := TestBasis(t, opts...)
	p, _ := b.LoadProject([]ProjectOption{
		WithProjectRef(&vagrant_plugin_sdk.Ref_Project{
			Basis: b.Ref().(*vagrant_plugin_sdk.Ref_Basis),
			Name:  "test-project"},
		),
	}...)
	return p
}

// TestMinimalProject uses a minimal basis to setup the most basic project
// that will work for testing
func TestMinimalProject(t testing.T) *Project {
	pluginManager := plugin.NewManager(
		context.Background(),
		hclog.New(&hclog.LoggerOptions{}),
	)

	b := TestBasis(t, WithPluginManager(pluginManager))

	p, _ := b.LoadProject([]ProjectOption{
		WithProjectRef(&vagrant_plugin_sdk.Ref_Project{
			Basis: b.Ref().(*vagrant_plugin_sdk.Ref_Basis),
			Name:  "test-project"},
		),
	}...)
	return p
}
