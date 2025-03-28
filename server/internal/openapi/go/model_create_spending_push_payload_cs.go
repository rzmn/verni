// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

// CreateSpendingPushPayloadCs - Create spending push payload
type CreateSpendingPushPayloadCs struct {

	// Group identifier
	Gid string `json:"gid"`

	// Group name
	Gn *string `json:"gn,omitempty"`

	// Spending identifier
	Sid string `json:"sid"`

	// Spending name
	Sn string `json:"sn"`

	// Participant display names
	Pdns map[string]string `json:"pdns"`

	// Currency
	C string `json:"c"`

	// Amount
	A int64 `json:"a"`

	// User's amount
	U int64 `json:"u"`
}

// AssertCreateSpendingPushPayloadCsRequired checks if the required fields are not zero-ed
func AssertCreateSpendingPushPayloadCsRequired(obj CreateSpendingPushPayloadCs) error {
	elements := map[string]interface{}{
		"gid":  obj.Gid,
		"sid":  obj.Sid,
		"sn":   obj.Sn,
		"pdns": obj.Pdns,
		"c":    obj.C,
		"a":    obj.A,
		"u":    obj.U,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	return nil
}

// AssertCreateSpendingPushPayloadCsConstraints checks if the values respects the defined constraints
func AssertCreateSpendingPushPayloadCsConstraints(obj CreateSpendingPushPayloadCs) error {
	return nil
}
