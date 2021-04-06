package ptypes

import (
	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/imdario/mergo"
	"github.com/mitchellh/go-testing-interface"
	"github.com/stretchr/testify/require"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
)

// TestProject returns a valid project for tests.
func TestProject(t testing.T, src *vagrant_server.Project) *vagrant_server.Project {
	t.Helper()

	if src == nil {
		src = &vagrant_server.Project{}
	}

	require.NoError(t, mergo.Merge(src, &vagrant_server.Project{
		Name: "test",
	}))

	return src
}

// Type wrapper around the proto type so that we can add some methods.
type Project struct{ *vagrant_server.Project }

// MachineIdx returns the index of the machine with the given resource id or -1 if its not found.
func (p *Project) MachineIdx(n string) int {
	for i, machine := range p.Machines {
		if machine.ResourceId == n {
			return i
		}
	}

	return -1
}

// Machine returns the machine with the given resource id. Returns nil if not found.
func (p *Project) Machine(n string) *vagrant_server.Ref_Machine {
	for _, machine := range p.Machines {
		if machine.ResourceId == n {
			return machine
		}
	}
	return nil
}

func (p *Project) AddMachine(m *vagrant_server.Machine) bool {
	return p.AddMachineRef(
		&vagrant_server.Ref_Machine{
			Project:    m.Project,
			Name:       m.Name,
			ResourceId: m.ResourceId,
		},
	)
}

func (p *Project) AddMachineRef(m *vagrant_server.Ref_Machine) bool {
	i := p.MachineIdx(m.ResourceId)
	if i >= 0 {
		return false
	}
	p.Project.Machines = append(p.Project.Machines, m)
	return true
}

func (p *Project) DeleteMachine(m *vagrant_server.Machine) bool {
	return p.DeleteMachineRef(
		&vagrant_server.Ref_Machine{
			Project:    m.Project,
			Name:       m.Name,
			ResourceId: m.ResourceId,
		},
	)
}

func (p *Project) DeleteMachineRef(m *vagrant_server.Ref_Machine) bool {
	i := p.MachineIdx(m.ResourceId)
	if i < 0 {
		return false
	}
	ms := p.Project.Machines
	ms[len(ms)-1], ms[i] = ms[i], ms[len(ms)-1]
	p.Project.Machines = ms
	return true
}

// ValidateProject validates the project structure.
func ValidateProject(p *vagrant_server.Project) error {
	return validation.ValidateStruct(p,
		validation.Field(&p.Name, validation.By(isEmpty)),
	)
}
