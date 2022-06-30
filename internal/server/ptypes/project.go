package ptypes

import (
	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// TestProject returns a valid project for tests.
func TestProject(t testing.T, src *vagrant_server.Project) *vagrant_server.Project {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Project{}
	}

	require.NoError(t, mergo.Merge(src, &vagrant_server.Project{
		Name:  "test",
		Basis: &vagrant_plugin_sdk.Ref_Basis{},
	}))

	return src
}

// Type wrapper around the proto type so that we can add some methods.
type Project struct{ *vagrant_server.Project }

// MachineIdx returns the index of the machine with the given resource id or -1 if its not found.
func (p *Project) TargetIdx(n string) int {
	for i, target := range p.Targets {
		if target.ResourceId == n {
			return i
		}
	}

	return -1
}

// Machine returns the machine with the given resource id. Returns nil if not found.
func (p *Project) Target(n string) *vagrant_plugin_sdk.Ref_Target {
	for _, target := range p.Targets {
		if target.ResourceId == n {
			return target
		}
	}
	return nil
}

func (p *Project) AddTarget(m *vagrant_server.Target) bool {
	return p.AddTargetRef(
		&vagrant_plugin_sdk.Ref_Target{
			Project:    m.Project,
			Name:       m.Name,
			ResourceId: m.ResourceId,
		},
	)
}

func (p *Project) AddTargetRef(m *vagrant_plugin_sdk.Ref_Target) bool {
	i := p.TargetIdx(m.ResourceId)
	if i >= 0 {
		return false
	}
	p.Project.Targets = append(p.Project.Targets, m)
	return true
}

func (p *Project) DeleteTarget(m *vagrant_server.Target) bool {
	return p.DeleteTargetRef(
		&vagrant_plugin_sdk.Ref_Target{
			Project:    m.Project,
			Name:       m.Name,
			ResourceId: m.ResourceId,
		},
	)
}

func (p *Project) DeleteTargetRef(m *vagrant_plugin_sdk.Ref_Target) bool {
	i := p.TargetIdx(m.ResourceId)
	if i < 0 {
		return false
	}
	ms := make([]*vagrant_plugin_sdk.Ref_Target, len(p.Project.Targets)-1)
	copy(ms[0:], p.Project.Targets[0:i])
	copy(ms[i:], p.Project.Targets[i+1:])
	p.Project.Targets = ms
	return true
}

// ValidateProject validates the project structure.
func ValidateProject(p *vagrant_server.Project) error {
	return validation.ValidateStruct(p,
		validation.Field(&p.Name, validation.By(isEmpty)),
	)
}
