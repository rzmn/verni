// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type RefreshSessionRequest struct {
	RefreshToken string `json:"refreshToken"`
}

// AssertRefreshSessionRequestRequired checks if the required fields are not zero-ed
func AssertRefreshSessionRequestRequired(obj RefreshSessionRequest) error {
	elements := map[string]interface{}{
		"refreshToken": obj.RefreshToken,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	return nil
}

// AssertRefreshSessionRequestConstraints checks if the values respects the defined constraints
func AssertRefreshSessionRequestConstraints(obj RefreshSessionRequest) error {
	return nil
}
