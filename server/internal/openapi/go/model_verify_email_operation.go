// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type VerifyEmailOperation struct {
	VerifyEmail VerifyEmailOperationVerifyEmail `json:"verifyEmail"`
}

// AssertVerifyEmailOperationRequired checks if the required fields are not zero-ed
func AssertVerifyEmailOperationRequired(obj VerifyEmailOperation) error {
	elements := map[string]interface{}{
		"verifyEmail": obj.VerifyEmail,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	if err := AssertVerifyEmailOperationVerifyEmailRequired(obj.VerifyEmail); err != nil {
		return err
	}
	return nil
}

// AssertVerifyEmailOperationConstraints checks if the values respects the defined constraints
func AssertVerifyEmailOperationConstraints(obj VerifyEmailOperation) error {
	if err := AssertVerifyEmailOperationVerifyEmailConstraints(obj.VerifyEmail); err != nil {
		return err
	}
	return nil
}
