package state

import (
	"errors"

	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"github.com/hashicorp/vagrant/internal/server"
	"github.com/hashicorp/vagrant/internal/server/proto/vagrant_server"
	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

func init() {
	models = append(models, &Basis{})
}

// This interface is utilized internally as an
// identifier for scopes to allow for easier mapping
type scope interface {
	scope() interface{}
}

type Basis struct {
	Model

	Vagrantfile   *Vagrantfile `gorm:"constraint:OnDelete:SET NULL" mapstructure:"Configuration"`
	VagrantfileID *uint        `mapstructure:"-"`
	DataSource    *ProtoValue
	Jobs          []*InternalJob `gorm:"polymorphic:Scope" mapstructure:"-"`
	Metadata      MetadataSet
	Name          string     `gorm:"uniqueIndex,not null"`
	Path          string     `gorm:"uniqueIndex,not null"`
	Projects      []*Project `gorm:"constraint:OnDelete:SET NULL"`
	RemoteEnabled bool
	ResourceId    string `gorm:"uniqueIndex,not null"` // TODO(spox): readonly permission not working as expected
}

// Returns a fully populated instance of the current basis
func (b *Basis) find(db *gorm.DB) (*Basis, error) {
	var basis Basis
	result := db.Preload(clause.Associations).
		Where(&Basis{ResourceId: b.ResourceId}).
		Or(&Basis{Name: b.Name}).
		Or(&Basis{Path: b.Path}).
		Or(&Basis{Model: Model{ID: b.ID}}).
		First(&basis)
	if result.Error != nil {
		return nil, result.Error
	}

	return &basis, nil
}

func (b *Basis) scope() interface{} {
	return b
}

// Define custom table name
func (Basis) TableName() string {
	return "basis"
}

// Use before delete hook to remove all assocations
func (b *Basis) BeforeDelete(tx *gorm.DB) error {
	basis, err := b.find(tx)
	if err != nil {
		return err
	}

	// If Vagrantfile is attached, delete it
	if basis.VagrantfileID != nil {
		result := tx.Where(&Vagrantfile{Model: Model{ID: *basis.VagrantfileID}}).
			Delete(&Vagrantfile{})
		if result.Error != nil {
			return result.Error
		}
	}

	if len(basis.Projects) > 0 {
		if result := tx.Delete(basis.Projects); result.Error != nil {
			return result.Error
		}
	}

	if len(basis.Jobs) > 0 {
		result := tx.Delete(basis.Jobs)
		if result.Error != nil {
			return result.Error
		}
	}

	return nil
}

func (b *Basis) BeforeSave(tx *gorm.DB) error {
	if b.ResourceId == "" {
		if err := b.setId(); err != nil {
			return err
		}
	}
	if err := b.Validate(tx); err != nil {
		return err
	}

	return nil
}

func (b *Basis) BeforeUpdate(tx *gorm.DB) error {
	// If a Vagrantfile was already set for the basis, just update it
	if b.Vagrantfile != nil && b.Vagrantfile.ID == 0 && b.VagrantfileID != nil {
		var v Vagrantfile
		result := tx.First(&v, &Vagrantfile{Model: Model{ID: *b.VagrantfileID}})
		if result.Error != nil {
			return result.Error
		}
		id := v.ID
		if err := decode(b.Vagrantfile, &v); err != nil {
			return err
		}
		v.ID = id
		b.Vagrantfile = &v

		// NOTE: Just updating the value doesn't save the changes so
		//       save the changes in this transaction
		if result := tx.Save(&v); result.Error != nil {
			return result.Error
		}
	}
	return nil
}

func (b *Basis) Validate(tx *gorm.DB) error {
	// NOTE: We should be able to use `tx.Statement.Changed("ResourceId")`
	//       for change detection but it doesn't appear to be set correctly
	//       so we don't get any notice of change (maybe because it's a pointer?)
	existing, err := b.find(tx)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return err
	}

	if existing == nil {
		existing = &Basis{}
	}

	err = validation.ValidateStruct(b,
		validation.Field(&b.Name,
			validation.Required,
			validation.By(
				checkUnique(
					tx.Model(&Basis{}).
						Where(&Basis{Name: b.Name}).
						Not(&Basis{Model: Model{ID: b.ID}}),
				),
			),
		),
		validation.Field(&b.Path,
			validation.Required,
			validation.By(
				checkUnique(
					tx.Model(&Basis{}).
						Where(&Basis{Path: b.Path}).
						Not(&Basis{Model: Model{ID: b.ID}}),
				),
			),
		),
		validation.Field(&b.ResourceId,
			validation.Required,
			validation.By(
				checkUnique(
					tx.Model(&Basis{}).
						Where(&Basis{ResourceId: b.ResourceId}).
						Not(&Basis{Model: Model{ID: b.ID}}),
				),
			),
			validation.When(
				b.ID != 0,
				validation.By(
					checkNotModified(
						existing.ResourceId,
					),
				),
			),
		),
	)

	if err != nil {
		return err
	}

	return nil
}

func (b *Basis) setId() error {
	id, err := server.Id()
	if err != nil {
		return err
	}
	b.ResourceId = id

	return nil
}

// Convert basis to protobuf message
func (b *Basis) ToProto() *vagrant_server.Basis {
	if b == nil {
		return nil
	}

	basis := vagrant_server.Basis{}
	err := decode(b, &basis)
	if err != nil {
		panic("failed to decode basis: " + err.Error())
	}

	if b.Vagrantfile != nil {
		basis.Configuration = b.Vagrantfile.ToProto()
	}

	return &basis
}

// Convert basis to reference protobuf message
func (b *Basis) ToProtoRef() *vagrant_plugin_sdk.Ref_Basis {
	if b == nil {
		return nil
	}

	ref := vagrant_plugin_sdk.Ref_Basis{}
	err := decode(b, &ref)
	if err != nil {
		panic("failed to decode basis to ref: " + err.Error())
	}

	return &ref
}

// Load a Basis from a protobuf message. This will only search
// against the resource id.
func (s *State) BasisFromProto(
	b *vagrant_server.Basis,
) (*Basis, error) {
	if b == nil {
		return nil, ErrEmptyProtoArgument
	}

	basis, err := s.BasisFromProtoRef(
		&vagrant_plugin_sdk.Ref_Basis{
			ResourceId: b.ResourceId,
		},
	)
	if err != nil {
		return nil, err
	}

	return basis, nil
}

// Load a Basis from a protobuf message. This will attempt to locate the
// basis using any unique field it can match.
func (s *State) BasisFromProtoFuzzy(
	b *vagrant_server.Basis,
) (*Basis, error) {
	if b == nil {
		return nil, ErrEmptyProtoArgument
	}

	basis, err := s.BasisFromProtoRefFuzzy(
		&vagrant_plugin_sdk.Ref_Basis{
			ResourceId: b.ResourceId,
			Name:       b.Name,
			Path:       b.Path,
		},
	)
	if err != nil {
		return nil, err
	}

	return basis, nil
}

// Load a Basis from a reference protobuf message
func (s *State) BasisFromProtoRef(
	ref *vagrant_plugin_sdk.Ref_Basis,
) (*Basis, error) {
	if ref == nil {
		return nil, ErrEmptyProtoArgument
	}

	if ref.ResourceId == "" {
		return nil, gorm.ErrRecordNotFound
	}

	var basis Basis
	result := s.search().First(&basis, &Basis{ResourceId: ref.ResourceId})
	if result.Error != nil {
		return nil, result.Error
	}

	return &basis, nil
}

func (s *State) BasisFromProtoRefFuzzy(
	ref *vagrant_plugin_sdk.Ref_Basis,
) (*Basis, error) {
	basis, err := s.BasisFromProtoRef(ref)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, err
	}

	if basis != nil {
		return basis, nil
	}

	// If name and path are both empty, we can't search
	if ref.Name == "" && ref.Path == "" {
		return nil, gorm.ErrRecordNotFound
	}

	basis = &Basis{}
	query := &Basis{}

	if ref.Name != "" {
		query.Name = ref.Name
	}
	if ref.Path != "" {
		query.Path = ref.Path
	}

	result := s.search().First(basis, query)
	if result.Error != nil {
		return nil, result.Error
	}

	return basis, nil
}

// Get a basis record using a reference protobuf message.
func (s *State) BasisGet(
	ref *vagrant_plugin_sdk.Ref_Basis,
) (*vagrant_server.Basis, error) {
	b, err := s.BasisFromProtoRef(ref)
	if err != nil {
		return nil, lookupErrorToStatus("basis", err)
	}

	return b.ToProto(), nil
}

// Find a basis record using a protobuf message
func (s *State) BasisFind(
	b *vagrant_server.Basis,
) (*vagrant_server.Basis, error) {
	basis, err := s.BasisFromProtoFuzzy(b)
	if err != nil {
		return nil, lookupErrorToStatus("basis", err)
	}

	return basis.ToProto(), nil
}

// Store a basis record
func (s *State) BasisPut(
	b *vagrant_server.Basis,
) (*vagrant_server.Basis, error) {
	basis, err := s.BasisFromProto(b)
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, lookupErrorToStatus("basis", err)
	}

	// Make sure we don't have a nil
	if err != nil {
		basis = &Basis{}
	}

	err = s.softDecode(b, basis)
	if err != nil {
		return nil, saveErrorToStatus("basis", err)
	}

	if err := s.upsertFull(basis); err != nil {
		return nil, saveErrorToStatus("basis", err)
	}

	return basis.ToProto(), nil
}

// List all basis records
func (s *State) BasisList() ([]*Basis, error) {
	var all []*Basis
	result := s.search().Find(&all)
	if result.Error != nil {
		return nil, lookupErrorToStatus("basis", result.Error)
	}

	return all, nil
}

// Delete a basis
func (s *State) BasisDelete(
	b *vagrant_plugin_sdk.Ref_Basis,
) error {
	basis, err := s.BasisFromProtoRef(b)
	// If the record was not found, we return with no error
	if err != nil && errors.Is(err, gorm.ErrRecordNotFound) {
		return nil
	}

	// If an unexpected error was encountered, return it
	if err != nil {
		return lookupErrorToStatus("basis", err)
	}

	result := s.db.Delete(basis)
	if result.Error != nil {
		return deleteErrorToStatus("basis", result.Error)
	}

	return nil
}

var (
	_ scope = (*Basis)(nil)
)
