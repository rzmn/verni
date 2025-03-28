// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type PushOperationsRequest struct {
	Operations []SomeOperation `json:"operations"`
}

// AssertPushOperationsRequestRequired checks if the required fields are not zero-ed
func AssertPushOperationsRequestRequired(obj PushOperationsRequest) error {
	elements := map[string]interface{}{
		"operations": obj.Operations,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	for _, el := range obj.Operations {
		if err := AssertSomeOperationRequired(el); err != nil {
			return err
		}
	}
	return nil
}

// AssertPushOperationsRequestConstraints checks if the values respects the defined constraints
func AssertPushOperationsRequestConstraints(obj PushOperationsRequest) error {
	for _, el := range obj.Operations {
		if err := AssertSomeOperationConstraints(el); err != nil {
			return err
		}
	}
	return nil
}
