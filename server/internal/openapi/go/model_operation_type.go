// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

import (
	"fmt"
)

type OperationType string

// List of OperationType
const (
	REGULAR OperationType = "regular"
	LARGE   OperationType = "large"
)

// AllowedOperationTypeEnumValues is all the allowed values of OperationType enum
var AllowedOperationTypeEnumValues = []OperationType{
	"regular",
	"large",
}

// validOperationTypeEnumValue provides a map of OperationTypes for fast verification of use input
var validOperationTypeEnumValues = map[OperationType]struct{}{
	"regular": {},
	"large":   {},
}

// IsValid return true if the value is valid for the enum, false otherwise
func (v OperationType) IsValid() bool {
	_, ok := validOperationTypeEnumValues[v]
	return ok
}

// NewOperationTypeFromValue returns a pointer to a valid OperationType
// for the value passed as argument, or an error if the value passed is not allowed by the enum
func NewOperationTypeFromValue(v string) (OperationType, error) {
	ev := OperationType(v)
	if ev.IsValid() {
		return ev, nil
	}

	return "", fmt.Errorf("invalid value '%v' for OperationType: valid values are %v", v, AllowedOperationTypeEnumValues)
}

// AssertOperationTypeRequired checks if the required fields are not zero-ed
func AssertOperationTypeRequired(obj OperationType) error {
	return nil
}

// AssertOperationTypeConstraints checks if the values respects the defined constraints
func AssertOperationTypeConstraints(obj OperationType) error {
	return nil
}
