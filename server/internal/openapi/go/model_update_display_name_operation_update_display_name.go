// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

// UpdateDisplayNameOperationUpdateDisplayName - Update display name operation
type UpdateDisplayNameOperationUpdateDisplayName struct {
	UserId string `json:"userId"`

	DisplayName string `json:"displayName"`
}

// AssertUpdateDisplayNameOperationUpdateDisplayNameRequired checks if the required fields are not zero-ed
func AssertUpdateDisplayNameOperationUpdateDisplayNameRequired(obj UpdateDisplayNameOperationUpdateDisplayName) error {
	elements := map[string]interface{}{
		"userId":      obj.UserId,
		"displayName": obj.DisplayName,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	return nil
}

// AssertUpdateDisplayNameOperationUpdateDisplayNameConstraints checks if the values respects the defined constraints
func AssertUpdateDisplayNameOperationUpdateDisplayNameConstraints(obj UpdateDisplayNameOperationUpdateDisplayName) error {
	return nil
}
