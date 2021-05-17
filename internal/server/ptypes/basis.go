package ptypes

import (
	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// TestBasis returns a valid basis for tests.
func TestBasis(t testing.T, src *vagrant_server.Basis) *vagrant_server.Basis {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Basis{}
	}

	require.NoError(t, mergo.Merge(src, &vagrant_server.Basis{
		Name: "test",
	}))

	return src
}

// Type wrapper around the proto type so that we can add some methods.
type Basis struct{ *vagrant_server.Basis }

// ProjectIdx returns the index of the project with the given resource id or -1 if its not found.
func (b *Basis) ProjectIdx(n string) int {
	for i, project := range b.Projects {
		if project.ResourceId == n {
			return i
		}
	}

	return -1
}

// Project returns the project with the given resource id. Returns nil if not found.
func (b *Basis) Project(n string) *vagrant_plugin_sdk.Ref_Project {
	for _, project := range b.Projects {
		if project.ResourceId == n {
			return project
		}
	}
	return nil
}

func (b *Basis) AddProject(p *vagrant_server.Project) bool {
	return b.AddProjectRef(
		&vagrant_plugin_sdk.Ref_Project{
			Basis:      p.Basis,
			Name:       p.Name,
			ResourceId: p.ResourceId,
		},
	)
}

func (b *Basis) AddProjectRef(p *vagrant_plugin_sdk.Ref_Project) bool {
	i := b.ProjectIdx(p.ResourceId)
	if i >= 0 {
		return false
	}
	b.Basis.Projects = append(b.Basis.Projects, p)
	return true
}

func (b *Basis) DeleteProject(p *vagrant_server.Project) bool {
	return b.DeleteProjectRef(
		&vagrant_plugin_sdk.Ref_Project{
			Basis:      p.Basis,
			Name:       p.Name,
			ResourceId: p.ResourceId,
		},
	)
}

func (b *Basis) DeleteProjectRef(p *vagrant_plugin_sdk.Ref_Project) bool {
	i := b.ProjectIdx(p.ResourceId)
	if i < 0 {
		return false
	}
	l := b.Basis.Projects
	l[len(l)-1], l[i] = l[i], l[len(l)-1]
	b.Basis.Projects = l
	return true
}

// ValidateBasis validates the basis structure.
func ValidateBasis(p *vagrant_server.Basis) error {
	return validation.ValidateStruct(p,
		validation.Field(&p.Name, validation.By(isEmpty)),
	)
}
