// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type CreateSpendingOperation struct {
	CreateSpending CreateSpendingOperationCreateSpending `json:"createSpending"`
}

// AssertCreateSpendingOperationRequired checks if the required fields are not zero-ed
func AssertCreateSpendingOperationRequired(obj CreateSpendingOperation) error {
	elements := map[string]interface{}{
		"createSpending": obj.CreateSpending,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	if err := AssertCreateSpendingOperationCreateSpendingRequired(obj.CreateSpending); err != nil {
		return err
	}
	return nil
}

// AssertCreateSpendingOperationConstraints checks if the values respects the defined constraints
func AssertCreateSpendingOperationConstraints(obj CreateSpendingOperation) error {
	if err := AssertCreateSpendingOperationCreateSpendingConstraints(obj.CreateSpending); err != nil {
		return err
	}
	return nil
}
