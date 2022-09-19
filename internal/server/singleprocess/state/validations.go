package state

import (
	"github.com/go-ozzo/ozzo-validation/v4"
	"gorm.io/gorm"
)

type ValidationCode string

const (
	VALIDATION_UNIQUE ValidationCode = "unique"
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
