// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type UpdateEmailRequest struct {
	Email string `json:"email"`
}

// AssertUpdateEmailRequestRequired checks if the required fields are not zero-ed
func AssertUpdateEmailRequestRequired(obj UpdateEmailRequest) error {
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

// AssertUpdateEmailRequestConstraints checks if the values respects the defined constraints
func AssertUpdateEmailRequestConstraints(obj UpdateEmailRequest) error {
	return nil
}
