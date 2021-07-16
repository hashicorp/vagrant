package core

import (
	"context"
	"io/ioutil"
	"os"

	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/mock"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/component"
	componentmocks "github.com/hashicorp/vagrant-plugin-sdk/component/mocks"
	"github.com/hashicorp/vagrant-plugin-sdk/datadir"
	"github.com/hashicorp/vagrant/internal/factory"
	"github.com/hashicorp/vagrant/internal/server/singleprocess"
)

// TestProject returns a fully in-memory and side-effect free Project that
// can be used for testing. Additional options can be given to provide your own
// factories, configuration, etc.
func TestProject(t testing.T, opts ...BasisOption) *Project {
	td, err := ioutil.TempDir("", "core")
	require.NoError(t, err)
	t.Cleanup(func() { os.RemoveAll(td) })

	projDir, err := datadir.NewBasis(td)
	require.NoError(t, err)

	defaultOpts := []BasisOption{
		WithClient(singleprocess.TestServer(t)),
		WithBasisDataDir(projDir),
		// WithBasisConfig
	}

	// Create the default factory for all component types
	for typ := range component.TypeMap {
		f, _ := TestFactorySingle(t, typ, "test")
		defaultOpts = append(defaultOpts, WithFactory(typ, f))
	}

	// p, err := NewProject(context.Background(), append(defaultOpts, opts...)...)
	// require.NoError(t, err)
	// t.Cleanup(func() { p.Close() })
	b, err := NewBasis(context.Background(), append(defaultOpts, opts...)...)

	p, err := b.LoadProject()
	return p
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
