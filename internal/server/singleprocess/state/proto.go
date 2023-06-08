package state

import (
	"database/sql"
	"database/sql/driver"
	"fmt"

	"github.com/hashicorp/vagrant-plugin-sdk/internal-shared/dynamic"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/migrator"
	"gorm.io/gorm/schema"
)

// ProtoValue stores a protobuf message in the database
// as a JSON field so it can be queried. Note that using
// this type can result in lossy storage depending on
// types in the message
type ProtoValue struct {
	Message proto.Message
}

// User consumable data type name
func (p *ProtoValue) GormDataType() string {
	return datatypes.JSON{}.GormDataType()
}

// Driver consumable data type name
func (p *ProtoValue) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	return datatypes.JSON{}.GormDBDataType(db, field)
}

// Unmarshals the store value back to original type
func (p *ProtoValue) Scan(value interface{}) error {
	if value == nil {
		return nil
	}

	s, ok := value.(string)
	if !ok {
		return fmt.Errorf("failed to unmarshal protobuf value, invalid type (%T)", value)
	}

	if s == "" {
		return nil
	}

	v := []byte(s)
	var m anypb.Any
	err := protojson.Unmarshal(v, &m)
	if err != nil {
		return err
	}

	_, i, err := dynamic.DecodeAny(&m)
	if err != nil {
		return err
	}

	pm, ok := i.(proto.Message)
	if !ok {
		return fmt.Errorf("failed to set unmarshaled proto value, invalid type (%T)", i)
	}

	p.Message = pm

	return nil
}

// Marshal the value for storage in the database
func (p *ProtoValue) Value() (driver.Value, error) {
	if p == nil || p.Message == nil {
		return nil, nil
	}

	a, err := dynamic.EncodeAny(p.Message)
	if err != nil {
		return nil, err
	}

	j, err := protojson.Marshal(a)
	if err != nil {
		return nil, err
	}
	return string(j), nil
}

// ProtoRaw stores a protobuf message in the database
// as raw bytes. Note that when using this type the
// contents of the protobuf message cannot be queried
type ProtoRaw struct {
	Message proto.Message
}

// User consumable data type name
func (p *ProtoRaw) GormDataType() string {
	return "bytes"
}

// Driver consumable data type name
func (p *ProtoRaw) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	return "BLOB"
}

// Unmarshals the store value back to original type
func (p *ProtoRaw) Scan(value interface{}) error {
	if p == nil || value == nil {
		return nil
	}

	s, ok := value.(string)
	if !ok {
		return fmt.Errorf("failed to unmarshal protobuf raw, invalid type (%T)", value)
	}

	if s == "" {
		return nil
	}

	v := []byte(s)
	var a anypb.Any
	err := proto.Unmarshal(v, &a)
	if err != nil {
		return err
	}
	_, m, err := dynamic.DecodeAny(&a)
	if err != nil {
		return err
	}

	pm, ok := m.(proto.Message)
	if !ok {
		return fmt.Errorf("failed to set unmarshaled proto raw, invalid type (%T)", m)
	}

	p.Message = pm

	return nil
}

// Marshal the value for storage in the database
func (p *ProtoRaw) Value() (driver.Value, error) {
	if p == nil || p.Message == nil {
		return nil, nil
	}

	m, err := dynamic.EncodeAny(p.Message)
	if err != nil {
		return nil, err
	}

	r, err := proto.Marshal(m)
	if err != nil {
		return nil, err
	}

	return string(r), nil
}

var (
	_ sql.Scanner                    = (*ProtoValue)(nil)
	_ driver.Valuer                  = (*ProtoValue)(nil)
	_ schema.GormDataTypeInterface   = (*ProtoValue)(nil)
	_ migrator.GormDataTypeInterface = (*ProtoValue)(nil)
	_ sql.Scanner                    = (*ProtoRaw)(nil)
	_ driver.Valuer                  = (*ProtoRaw)(nil)
	_ schema.GormDataTypeInterface   = (*ProtoRaw)(nil)
	_ migrator.GormDataTypeInterface = (*ProtoRaw)(nil)
)
