package state

import (
	"fmt"
	"reflect"

	"github.com/go-ozzo/ozzo-validation/v4"
	"github.com/hashicorp/go-version"
	"gorm.io/gorm"
)

type ValidationCode string

const (
	VALIDATION_UNIQUE   ValidationCode = "unique"
	VALIDATION_MODIFIED                = "modified"
	VALIDATION_PROJECT                 = "project"
	VALIDATION_TYPE                    = "type"
	VALIDATION_VERSION                 = "version"
)

func checkUnique(tx *gorm.DB) validation.RuleFunc {
	return func(value interface{}) error {
		var count int64
		result := tx.Count(&count)
		if result.Error != nil {
			return validation.NewInternalError(result.Error)
		}

		if count > 0 {
			return validation.NewError(
				string(VALIDATION_UNIQUE),
				"must be unique",
			)
		}

		return nil
	}
}

func checkNotModified(original interface{}) validation.RuleFunc {
	return func(value interface{}) error {
		if !reflect.DeepEqual(original, value) {
			return validation.NewError(
				string(VALIDATION_MODIFIED),
				"cannot be modified",
			)
		}

		return nil
	}
}

func checkSameProject(projectID uint) validation.RuleFunc {
	return func(value interface{}) error {
		vPid, ok := value.(uint)
		if !ok {
			project, ok := value.(*Project)
			if !ok {
				return validation.NewError(
					string(VALIDATION_TYPE),
					fmt.Sprintf("*Project or uint required for validation (%T)", value),
				)
			}
			vPid = project.ID
		}
		if vPid != projectID {
			return validation.NewError(
				string(VALIDATION_PROJECT),
				"project must match parent project",
			)
		}
		return nil
	}
}

func checkValidVersion(value interface{}) error {
	v, ok := value.(string)
	if !ok {
		return validation.NewError(
			string(VALIDATION_TYPE),
			fmt.Sprintf("version string required for validation (%T)", value),
		)
	}
	_, err := version.NewVersion(v)
	if err != nil {
		return validation.NewError(
			string(VALIDATION_VERSION),
			"invalid version string",
		)
	}

	return nil
}
