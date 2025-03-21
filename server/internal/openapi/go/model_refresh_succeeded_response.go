// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type RefreshSucceededResponse struct {
	Response Session `json:"response"`
}

// AssertRefreshSucceededResponseRequired checks if the required fields are not zero-ed
func AssertRefreshSucceededResponseRequired(obj RefreshSucceededResponse) error {
	elements := map[string]interface{}{
		"response": obj.Response,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	if err := AssertSessionRequired(obj.Response); err != nil {
		return err
	}
	return nil
}

// AssertRefreshSucceededResponseConstraints checks if the values respects the defined constraints
func AssertRefreshSucceededResponseConstraints(obj RefreshSucceededResponse) error {
	if err := AssertSessionConstraints(obj.Response); err != nil {
		return err
	}
	return nil
}
