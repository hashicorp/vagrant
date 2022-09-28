package state

import (
	"errors"
	"fmt"
	"time"

	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/go-ozzo/ozzo-validation/v4/is"
	"github.com/hashicorp/go-version"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"github.com/mitchellh/mapstructure"
	"gorm.io/gorm"
)

func init() {
	models = append(models, &Box{})
}

const (
	DEFAULT_BOX_VERSION    = "0.0.0"
	DEFAULT_BOX_CONSTRAINT = "> 0"
)

type Box struct {
	Model

	Directory   *string    `gorm:"not null"`
	LastUpdate  *time.Time `gorm:"autoUpdateTime"`
	Metadata    *ProtoValue
	MetadataUrl *string
	Name        *string `gorm:"uniqueIndex:idx_nameverprov;not null"`
	Provider    *string `gorm:"uniqueIndex:idx_nameverprov;not null"`
	ResourceId  *string `gorm:"<-:create;uniqueIndex;not null"`
	Version     *string `gorm:"uniqueIndex:idx_nameverprov;not null"`
}

func (b *Box) BeforeSave(tx *gorm.DB) error {
	if b.ResourceId == nil {
		if err := b.setId(); err != nil {
			return err
		}
	}

	// If version is not set, default it to 0
	if b.Version == nil || *b.Version == "0" {
		v := DEFAULT_BOX_VERSION
		b.Version = &v
	}

	if err := b.Validate(tx); err != nil {
		return err
	}

	return nil
}

func (b *Box) setId() error {
	id, err := server.Id()
	if err != nil {
		return err
	}
	b.ResourceId = &id

	return nil
}

func (b *Box) Validate(tx *gorm.DB) error {
	err := validation.ValidateStruct(b,
		validation.Field(&b.Directory, validation.Required),
		validation.Field(&b.Name, validation.Required),
		validation.Field(&b.Provider, validation.Required),
		validation.Field(&b.ResourceId,
			validation.Required,
			validation.By(
				checkUnique(
					tx.Model(&Box{}).
						Where(&Box{ResourceId: b.ResourceId}).
						Not(&Box{Model: Model{ID: b.ID}}),
				),
			),
		),
		validation.Field(&b.Version,
			validation.Required,
			is.Semver,
		),
	)

	if err != nil {
		return err
	}

	err = validation.Validate(b,
		validation.By(
			checkUnique(
				tx.Model(&Box{}).
					Where(&Box{Name: b.Name, Provider: b.Provider, Version: b.Version}).
					Not(&Box{Model: Model{ID: b.ID}}),
			),
		),
	)

	if err != nil {
		return fmt.Errorf("name, provider and version %s", err)
	}

	return nil
}

func (b *Box) ToProto() *vagrant_server.Box {
	var p vagrant_server.Box
	err := decode(b, &p)
	if err != nil {
		panic(fmt.Sprintf("failed to decode box: " + err.Error()))
	}

	return &p
}

func (b *Box) ToProtoRef() *vagrant_plugin_sdk.Ref_Box {
	var p vagrant_plugin_sdk.Ref_Box
	err := decode(b, &p)
	if err != nil {
		panic(fmt.Sprintf("failed to decode box ref: " + err.Error()))
	}

	return &p
}

func (s *State) BoxFromProtoRef(
	b *vagrant_plugin_sdk.Ref_Box,
) (*Box, error) {
	if b == nil {
		return nil, ErrEmptyProtoArgument
	}

	if b.ResourceId == "" {
		return nil, gorm.ErrRecordNotFound
	}

	var box Box
	result := s.search().First(&box, &Box{ResourceId: &b.ResourceId})
	if result.Error != nil {
		return nil, result.Error
	}

	return &box, nil
}

func (s *State) BoxFromProtoRefFuzzy(
	b *vagrant_plugin_sdk.Ref_Box,
) (*Box, error) {
	box, err := s.BoxFromProtoRef(b)
	if err == nil {
		return box, nil
	}

	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	if b.Name == "" || b.Provider == "" || b.Version == "" {
		return nil, gorm.ErrRecordNotFound
	}

	box = &Box{}
	result := s.search().First(box,
		&Box{
			Name:     &b.Name,
			Provider: &b.Provider,
			Version:  &b.Version,
		},
	)
	if result.Error != nil {
		return nil, result.Error
	}

	return box, nil
}

func (s *State) BoxFromProto(
	b *vagrant_server.Box,
) (*Box, error) {
	return s.BoxFromProtoRef(
		&vagrant_plugin_sdk.Ref_Box{
			ResourceId: b.ResourceId,
		},
	)
}

func (s *State) BoxFromProtoFuzzy(
	b *vagrant_server.Box,
) (*Box, error) {
	return s.BoxFromProtoRefFuzzy(
		&vagrant_plugin_sdk.Ref_Box{
			Name:       b.Name,
			Provider:   b.Provider,
			ResourceId: b.ResourceId,
			Version:    b.Version,
		},
	)
}

func (s *State) BoxList() ([]*vagrant_plugin_sdk.Ref_Box, error) {
	var boxes []Box
	result := s.db.Find(&boxes)
	if result.Error != nil {
		return nil, lookupErrorToStatus("boxes", result.Error)
	}
	refs := make([]*vagrant_plugin_sdk.Ref_Box, len(boxes))
	for i, b := range boxes {
		refs[i] = b.ToProtoRef()
	}
	return refs, nil
}

func (s *State) BoxDelete(
	b *vagrant_plugin_sdk.Ref_Box,
) error {
	box, err := s.BoxFromProtoRef(b)
	if err != nil && errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}

	if err != nil {
		return deleteErrorToStatus("box", err)
	}

	result := s.db.Delete(box)
	if result.Error != nil {
		return deleteErrorToStatus("box", result.Error)
	}

	return nil
}

func (s *State) BoxGet(
	b *vagrant_plugin_sdk.Ref_Box,
) (*vagrant_server.Box, error) {
	box, err := s.BoxFromProtoRef(b)
	if err != nil {
		return nil, lookupErrorToStatus("box", err)
	}

	return box.ToProto(), nil
}

func (s *State) BoxPut(b *vagrant_server.Box) error {
	box, err := s.BoxFromProto(b)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return lookupErrorToStatus("box", err)
	}

	if err != nil {
		box = &Box{}
	}

	err = s.softDecode(b, box)
	if err != nil {
		return saveErrorToStatus("box", err)
	}

	if err := s.upsertFull(box); err != nil {
		return saveErrorToStatus("box", err)
	}

	return nil
}

func (s *State) BoxFind(
	ref *vagrant_plugin_sdk.Ref_Box,
) (*vagrant_server.Box, error) {
	b := &vagrant_plugin_sdk.Ref_Box{}
	if err := mapstructure.Decode(ref, b); err != nil {
		return nil, lookupErrorToStatus("box", err)
	}

	if b.ResourceId != "" {
		box, err := s.BoxFromProtoRef(b)
		if err != nil {
			return nil, lookupErrorToStatus("box", err)
		}
		return box.ToProto(), nil
	}

	// If no name is given, we error immediately
	if b.Name == "" {
		return nil, lookupErrorToStatus("box", fmt.Errorf("no name given for box lookup"))
	}
	// If no provider is given, we error immediately
	if b.Provider == "" {
		return nil, lookupErrorToStatus("box", fmt.Errorf("no provider given for box lookup"))
	}

	// If the version is set to 0, mark it as default
	if b.Version == "0" {
		b.Version = DEFAULT_BOX_VERSION
	}

	// If we are provided an explicit version, just do a direct lookup
	if _, err := version.NewVersion(b.Version); err == nil {
		box, err := s.BoxFromProtoRefFuzzy(b)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				return nil, nil
			}
			return nil, lookupErrorToStatus("box", err)
		}

		return box.ToProto(), nil
	}

	var boxes []Box
	result := s.search().Find(&boxes,
		&Box{
			Name:     &b.Name,
			Provider: &b.Provider,
		},
	)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return nil, nil
		}
		return nil, lookupErrorToStatus("box", result.Error)
	}

	// If we found no boxes, return a not found error
	if len(boxes) < 1 {
		return nil, nil // lookupErrorToStatus("box", gorm.ErrRecordNotFound)
	}

	// If we have no version value set, apply the default
	// version constraint
	if b.Version == "" {
		b.Version = DEFAULT_BOX_CONSTRAINT
	}

	var match *Box
	highestVersion, _ := version.NewVersion("0.0.0")
	versionConstraint, err := version.NewConstraint(b.Version)
	if err != nil {
		return nil, lookupErrorToStatus("box", err)
	}

	for _, box := range boxes {
		boxVersion, err := version.NewVersion(*box.Version)
		if err != nil {
			return nil, lookupErrorToStatus("box", err)
		}
		if !versionConstraint.Check(boxVersion) {
			continue
		}
		if boxVersion.GreaterThan(highestVersion) {
			match = &box
			highestVersion = boxVersion
		}
	}

	if match != nil {
		return match.ToProto(), nil
	}

	return nil, nil // lookupErrorToStatus("box", gorm.ErrRecordNotFound)
}
