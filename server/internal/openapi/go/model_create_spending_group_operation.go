// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type CreateSpendingGroupOperation struct {
	CreateSpendingGroup CreateSpendingGroupOperationCreateSpendingGroup `json:"createSpendingGroup"`
}

// AssertCreateSpendingGroupOperationRequired checks if the required fields are not zero-ed
func AssertCreateSpendingGroupOperationRequired(obj CreateSpendingGroupOperation) error {
	elements := map[string]interface{}{
		"createSpendingGroup": obj.CreateSpendingGroup,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	if err := AssertCreateSpendingGroupOperationCreateSpendingGroupRequired(obj.CreateSpendingGroup); err != nil {
		return err
	}
	return nil
}

// AssertCreateSpendingGroupOperationConstraints checks if the values respects the defined constraints
func AssertCreateSpendingGroupOperationConstraints(obj CreateSpendingGroupOperation) error {
	if err := AssertCreateSpendingGroupOperationCreateSpendingGroupConstraints(obj.CreateSpendingGroup); err != nil {
		return err
	}
	return nil
}
