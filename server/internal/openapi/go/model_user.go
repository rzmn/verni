// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

// User - User.
type User struct {

	// User Identifier.
	Id string `json:"id"`

	// Users owner Identifier.
	OwnerId string `json:"ownerId"`

	// Display name.
	DisplayName string `json:"displayName"`

	// Avatar Identifier.
	AvatarId *string `json:"avatarId,omitempty"`
}

// AssertUserRequired checks if the required fields are not zero-ed
func AssertUserRequired(obj User) error {
	elements := map[string]interface{}{
		"id":          obj.Id,
		"ownerId":     obj.OwnerId,
		"displayName": obj.DisplayName,
	}
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	return nil
}

// AssertUserConstraints checks if the values respects the defined constraints
func AssertUserConstraints(obj User) error {
	return nil
}
