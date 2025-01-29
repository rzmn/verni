// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

// UpdateDisplayNameOperation - Update display name operation
type UpdateDisplayNameOperation struct {
	UpdateDisplayName CreateUserOperationCreateUser `json:"updateDisplayName"`
}

// AssertUpdateDisplayNameOperationRequired checks if the required fields are not zero-ed
func AssertUpdateDisplayNameOperationRequired(obj UpdateDisplayNameOperation) error {
	elements := map[string]interface{}{
		"updateDisplayName": obj.UpdateDisplayName,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	if err := AssertCreateUserOperationCreateUserRequired(obj.UpdateDisplayName); err != nil {
		return err
	}
	return nil
}

// AssertUpdateDisplayNameOperationConstraints checks if the values respects the defined constraints
func AssertUpdateDisplayNameOperationConstraints(obj UpdateDisplayNameOperation) error {
	if err := AssertCreateUserOperationCreateUserConstraints(obj.UpdateDisplayName); err != nil {
		return err
	}
	return nil
}
