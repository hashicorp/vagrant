package state

import (
	"errors"
	"fmt"

	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/hashicorp/go-hclog"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"gorm.io/gorm"
)

func init() {
	models = append(models, &Target{})
}

type Target struct {
	gorm.Model

	Configuration *ProtoRaw
	Jobs          []*InternalJob `gorm:"polymorphic:Scope;" mapstructure:"-"`
	Metadata      MetadataSet
	Name          *string `gorm:"uniqueIndex:idx_pname;not null"`
	Parent        *Target `gorm:"foreignkey:ID"`
	ParentID      uint    `mapstructure:"-"`
	Project       *Project
	ProjectID     *uint `gorm:"uniqueIndex:idx_pname;not null" mapstructure:"-"`
	Provider      *string
	Record        *ProtoRaw
	ResourceId    *string `gorm:"<-:create;uniqueIndex;not null"`
	State         vagrant_server.Operation_PhysicalState
	Subtargets    []*Target `gorm:"foreignkey:ParentID"`
	Uuid          *string   `gorm:"uniqueIndex"`
	l             hclog.Logger
}

func (t *Target) scope() interface{} {
	return t
}

// Set a public ID on the target before creating
func (t *Target) BeforeSave(tx *gorm.DB) error {
	if t.ResourceId == nil {
		if err := t.setId(); err != nil {
			return err
		}
	}

	if err := t.validate(tx); err != nil {
		return err
	}

	return nil
}

func (t *Target) validate(tx *gorm.DB) error {
	err := validation.ValidateStruct(t,
		validation.Field(&t.Name,
			validation.Required,
			validation.By(
				checkUnique(
					tx.Model(&Target{}).
						Where(&Target{Name: t.Name, ProjectID: t.ProjectID}).
						Not(&Target{Model: gorm.Model{ID: t.ID}}),
				),
			),
		),
		validation.Field(&t.ResourceId,
			validation.Required,
			validation.By(
				checkUnique(
					tx.Model(&Target{}).
						Where(&Target{ResourceId: t.ResourceId}).
						Not(&Target{Model: gorm.Model{ID: t.ID}}),
				),
			),
		),
		validation.Field(&t.Uuid,
			validation.When(t.Uuid != nil,
				validation.By(
					checkUnique(
						tx.Model(&Target{}).
							Where(&Target{Uuid: t.Uuid}).
							Not(&Target{Model: gorm.Model{ID: t.ID}}),
					),
				),
			),
		),
		// validation.Field(&t.ProjectID, validation.Required), TODO(spox): why are these empty?
	)

	if err != nil {
		return err
	}

	return nil
}

func (t *Target) setId() error {
	id, err := server.Id()
	if err != nil {
		return err
	}
	t.ResourceId = &id

	return nil
}

// Convert target to reference protobuf message
func (t *Target) ToProtoRef() *vagrant_plugin_sdk.Ref_Target {
	if t == nil {
		return nil
	}

	var ref vagrant_plugin_sdk.Ref_Target

	err := decode(t, &ref)
	if err != nil {
		panic("failed to decode target to ref: " + err.Error())
	}

	return &ref
}

// Convert target to protobuf message
func (t *Target) ToProto() *vagrant_server.Target {
	if t == nil {
		return nil
	}

	var target vagrant_server.Target

	err := decode(t, &target)
	if err != nil {
		panic("failed to decode target: " + err.Error())
	}

	return &target
}

// Load a Target from reference protobuf message
func (s *State) TargetFromProtoRef(
	ref *vagrant_plugin_sdk.Ref_Target,
) (*Target, error) {
	if ref == nil {
		return nil, ErrEmptyProtoArgument
	}

	if ref.ResourceId == "" {
		return nil, gorm.ErrRecordNotFound
	}

	var target Target
	result := s.search().Preload("Project.Basis").First(&target,
		&Target{ResourceId: &ref.ResourceId},
	)
	if result.Error != nil {
		return nil, result.Error
	}

	return &target, nil
}

func (s *State) TargetFromProtoRefFuzzy(
	ref *vagrant_plugin_sdk.Ref_Target,
) (*Target, error) {
	target, err := s.TargetFromProtoRef(ref)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	if ref.Project == nil {
		return nil, ErrMissingProtoParent
	}

	if ref.Name == "" {
		return nil, gorm.ErrRecordNotFound
	}

	target = &Target{}
	result := s.search().
		Joins("Project", &Project{ResourceId: &ref.Project.ResourceId}).
		Preload("Project.Basis").
		First(target, &Target{Name: &ref.Name})

	if result.Error != nil {
		return nil, result.Error
	}

	return target, nil
}

// Load a Target from protobuf message
func (s *State) TargetFromProto(
	t *vagrant_server.Target,
) (*Target, error) {
	target, err := s.TargetFromProtoRef(
		&vagrant_plugin_sdk.Ref_Target{
			ResourceId: t.ResourceId,
		},
	)

	if err != nil {
		return nil, err
	}

	return target, nil
}

func (s *State) TargetFromProtoFuzzy(
	t *vagrant_server.Target,
) (*Target, error) {
	target, err := s.TargetFromProto(t)
	if err == nil {
		return target, nil
	}

	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	if t.Project == nil {
		return nil, ErrMissingProtoParent
	}

	target = &Target{}
	query := &Target{Name: &t.Name}
	tx := s.db.
		Preload("Project",
			s.db.Where(
				&Project{ResourceId: &t.Project.ResourceId},
			),
		)
	if t.Name != "" {
		query.Name = &t.Name
	}
	if t.Uuid != "" {
		query.Uuid = &t.Uuid
		tx = tx.Or("uuid LIKE ?", fmt.Sprintf("%%%s%%", t.Uuid))
	}

	result := s.search().Joins("Project").
		Preload("Project.Basis").
		Where("Project.resource_id = ?", t.Project.ResourceId).
		First(target, query)
	if result.Error != nil {
		return nil, result.Error
	}

	return target, nil
}

// Get a target record using a reference protobuf message
func (s *State) TargetGet(
	ref *vagrant_plugin_sdk.Ref_Target,
) (*vagrant_server.Target, error) {
	t, err := s.TargetFromProtoRef(ref)
	if err != nil {
		return nil, lookupErrorToStatus("target", err)
	}

	return t.ToProto(), nil
}

// List all target records
func (s *State) TargetList() ([]*vagrant_plugin_sdk.Ref_Target, error) {
	var targets []Target
	result := s.search().Find(&targets)
	if result.Error != nil {
		return nil, lookupErrorToStatus("targets", result.Error)
	}

	trefs := make([]*vagrant_plugin_sdk.Ref_Target, len(targets))
	for i, t := range targets {
		trefs[i] = t.ToProtoRef()
	}

	return trefs, nil
}

// Delete a target by reference protobuf message
func (s *State) TargetDelete(
	t *vagrant_plugin_sdk.Ref_Target,
) error {
	target, err := s.TargetFromProtoRef(t)
	if err != nil && errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}

	if err != nil {
		return lookupErrorToStatus("target", err)
	}

	result := s.db.Delete(target)
	if result.Error != nil {
		return deleteErrorToStatus("target", result.Error)
	}

	return nil
}

// Store a Target
func (s *State) TargetPut(
	t *vagrant_server.Target,
) (*vagrant_server.Target, error) {
	target, err := s.TargetFromProto(t)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, lookupErrorToStatus("target", err)
	}

	// Make sure we don't have a nil
	if err != nil {
		target = &Target{}
	}

	s.log.Info("pre-decode our target project", "project", target.Project)

	err = s.softDecode(t, target)
	if err != nil {
		return nil, saveErrorToStatus("target", err)
	}

	s.log.Info("post-decode our target project", "project", target.Project)

	if target.Project == nil {
		panic("stop")
	}
	result := s.db.Save(target)

	s.log.Info("after save target project status", "project", target.Project, "error", err)
	if result.Error != nil {
		return nil, saveErrorToStatus("target", result.Error)
	}

	return target.ToProto(), nil
}

// Find a Target
func (s *State) TargetFind(
	t *vagrant_server.Target,
) (*vagrant_server.Target, error) {
	target, err := s.TargetFromProtoFuzzy(t)
	if err != nil {
		return nil, lookupErrorToStatus("target", err)
	}

	return target.ToProto(), nil
}

var (
	_ scope = (*Target)(nil)
)
