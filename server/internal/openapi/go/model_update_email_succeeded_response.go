// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type UpdateEmailSucceededResponse struct {
	Response map[string]interface{} `json:"response"`
}

// AssertUpdateEmailSucceededResponseRequired checks if the required fields are not zero-ed
func AssertUpdateEmailSucceededResponseRequired(obj UpdateEmailSucceededResponse) error {
	elements := map[string]interface{}{
		"response": obj.Response,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	return nil
}

// AssertUpdateEmailSucceededResponseConstraints checks if the values respects the defined constraints
func AssertUpdateEmailSucceededResponseConstraints(obj UpdateEmailSucceededResponse) error {
	return nil
}
