// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

// UpdateEmailOperationUpdateEmail - Update email operation
type UpdateEmailOperationUpdateEmail struct {
	Email string `json:"email"`
}

// AssertUpdateEmailOperationUpdateEmailRequired checks if the required fields are not zero-ed
func AssertUpdateEmailOperationUpdateEmailRequired(obj UpdateEmailOperationUpdateEmail) error {
	elements := map[string]interface{}{
		"email": obj.Email,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	return nil
}

// AssertUpdateEmailOperationUpdateEmailConstraints checks if the values respects the defined constraints
func AssertUpdateEmailOperationUpdateEmailConstraints(obj UpdateEmailOperationUpdateEmail) error {
	return nil
}
