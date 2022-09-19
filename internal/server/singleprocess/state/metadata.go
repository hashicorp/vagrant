package state

import (
	"database/sql"
	"database/sql/driver"
	"encoding/json"
	"fmt"

	"github.com/hashicorp/vagrant-plugin-sdk/proto/vagrant_plugin_sdk"
	"gorm.io/datatypes"
	"gorm.io/gorm"
	"gorm.io/gorm/migrator"
	"gorm.io/gorm/schema"
)

// MetadataSet is a simple map with a string key type
// and string value type. It is stored within the database
// as a JSON type so it can be queried.
type MetadataSet map[string]string

// User consumable data type name
func (m MetadataSet) GormDataType() string {
	return datatypes.JSON{}.GormDataType()
}

// Driver consumable data type name
func (m MetadataSet) GormDBDataType(db *gorm.DB, field *schema.Field) string {
	return datatypes.JSON{}.GormDBDataType(db, field)
}

// Unmarshals the store value back to original type
func (m MetadataSet) Scan(value interface{}) error {
	v, ok := value.([]byte)
	if !ok {
		return fmt.Errorf("Failed to unmarshal JSON value: %v", value)
	}
	j := datatypes.JSON{}
	err := j.UnmarshalJSON(v)
	if err != nil {
		return err
	}
	result := MetadataSet{}
	err = json.Unmarshal(j, &result)
	if err != nil {
		return err
	}
	m = result
	return nil
}

// Marshal the value for storage in the database
func (m MetadataSet) Value() (driver.Value, error) {
	if len(m) < 1 {
		return nil, nil
	}
	v, err := json.Marshal(m)
	if err != nil {
		return nil, err
	}
	return string(v), nil
}

// Convert the MetadataSet into a protobuf message
func (m MetadataSet) ToProto() *vagrant_plugin_sdk.Args_MetadataSet {
	return &vagrant_plugin_sdk.Args_MetadataSet{
		Metadata: map[string]string(m),
	}
}

var (
	_ sql.Scanner                    = (*MetadataSet)(nil)
	_ driver.Valuer                  = (*MetadataSet)(nil)
	_ schema.GormDataTypeInterface   = (*ProtoValue)(nil)
	_ migrator.GormDataTypeInterface = (*ProtoValue)(nil)
)
