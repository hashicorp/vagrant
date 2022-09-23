package state

import (
	"errors"

	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"gorm.io/gorm"
)

type Runner struct {
	Model

	Rid        *string `gorm:"uniqueIndex;not null" mapstructure:"Id"`
	ByIdOnly   bool
	Components []*Component `gorm:"many2many:runner_components"`
}

func init() {
	models = append(models, &Runner{})
}

func (r *Runner) ToProto() *vagrant_server.Runner {
	if r == nil {
		return nil
	}

	components := make([]*vagrant_server.Component, len(r.Components))
	for i, c := range r.Components {
		components[i] = c.ToProto()
	}
	return &vagrant_server.Runner{
		Id:         *r.Rid,
		ByIdOnly:   r.ByIdOnly,
		Components: components,
	}
}

func (s *State) RunnerFromProto(p *vagrant_server.Runner) (*Runner, error) {
	if p.Id == "" {
		return nil, gorm.ErrRecordNotFound
	}

	var runner Runner
	result := s.search().First(&runner, &Runner{Rid: &p.Id})
	if result.Error != nil {
		return nil, result.Error
	}

	return &runner, nil
}

func (s *State) RunnerById(id string) (*vagrant_server.Runner, error) {
	r, err := s.RunnerFromProto(&vagrant_server.Runner{Id: id})
	if err != nil {
		return nil, lookupErrorToStatus("runner", err)
	}

	return r.ToProto(), nil
}

func (s *State) RunnerCreate(r *vagrant_server.Runner) error {
	runner, err := s.RunnerFromProto(r)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return lookupErrorToStatus("runner", err)
	}

	if err != nil {
		runner = &Runner{}
	}

	err = s.softDecode(r, runner)
	if err != nil {
		return saveErrorToStatus("runner", err)
	}

	result := s.db.Save(runner)
	if result.Error != nil {
		return saveErrorToStatus("runner", result.Error)
	}

	return nil
}

func (s *State) RunnerDelete(id string) error {
	runner, err := s.RunnerFromProto(&vagrant_server.Runner{Id: id})
	if err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			return err
		}
		return nil
	}

	result := s.db.Delete(runner)
	if result.Error != nil {
		return deleteErrorToStatus("runner", result.Error)
	}

	return nil
}

// Returns if there are no registered runners
func (s *State) runnerEmpty() (bool, error) {
	var c int64
	result := s.db.Model(&Runner{}).Count(&c)
	if result.Error != nil {
		return false, result.Error
	}
	return c < 1, nil
}
