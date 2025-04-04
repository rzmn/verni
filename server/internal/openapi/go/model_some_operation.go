// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type SomeOperation struct {
	OperationId string `json:"operationId"`

	CreatedAt int64 `json:"createdAt"`

	AuthorId string `json:"authorId"`

	CreateUser CreateUserOperationCreateUser `json:"createUser"`

	BindUser BindUserOperationBindUser `json:"bindUser"`

	UpdateAvatar UpdateAvatarOperationUpdateAvatar `json:"updateAvatar"`

	UpdateDisplayName UpdateDisplayNameOperationUpdateDisplayName `json:"updateDisplayName"`

	CreateSpendingGroup CreateSpendingGroupOperationCreateSpendingGroup `json:"createSpendingGroup"`

	DeleteSpendingGroup DeleteSpendingGroupOperationDeleteSpendingGroup `json:"deleteSpendingGroup"`

	CreateSpending CreateSpendingOperationCreateSpending `json:"createSpending"`

	DeleteSpending DeleteSpendingOperationDeleteSpending `json:"deleteSpending"`

	UpdateEmail UpdateEmailOperationUpdateEmail `json:"updateEmail"`

	VerifyEmail VerifyEmailOperationVerifyEmail `json:"verifyEmail"`

	UploadImage UploadImageOperationUploadImage `json:"uploadImage"`
}

// AssertSomeOperationRequired checks if the required fields are not zero-ed
func AssertSomeOperationRequired(obj SomeOperation) error {
	return AssertSomeOperationConstraints(obj)
}

// AssertSomeOperationConstraints checks if the values respects the defined constraints
func AssertSomeOperationConstraints(obj SomeOperation) error {
	baseElements := map[string]interface{}{
		"operationId": obj.OperationId,
		"createdAt":   obj.CreatedAt,
		"authorId":    obj.AuthorId,
	}
	for name, el := range baseElements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	elements := map[string]interface{}{
		"operationId":         obj.OperationId,
		"createdAt":           obj.CreatedAt,
		"authorId":            obj.AuthorId,
		"createUser":          obj.CreateUser,
		"bindUser":            obj.BindUser,
		"updateAvatar":        obj.UpdateAvatar,
		"updateDisplayName":   obj.UpdateDisplayName,
		"createSpendingGroup": obj.CreateSpendingGroup,
		"deleteSpendingGroup": obj.DeleteSpendingGroup,
		"createSpending":      obj.CreateSpending,
		"deleteSpending":      obj.DeleteSpending,
		"updateEmail":         obj.UpdateEmail,
		"verifyEmail":         obj.VerifyEmail,
		"uploadImage":         obj.UploadImage,
	}

	matchesCount := 0
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			continue
		}
		switch name {
		case "createUser":
			if err := AssertCreateUserOperationCreateUserRequired(obj.CreateUser); err != nil {
				return err
			}
			matchesCount++
		case "bindUser":
			if err := AssertBindUserOperationBindUserRequired(obj.BindUser); err != nil {
				return err
			}
			matchesCount++
		case "updateAvatar":
			if err := AssertUpdateAvatarOperationUpdateAvatarRequired(obj.UpdateAvatar); err != nil {
				return err
			}
			matchesCount++
		case "updateDisplayName":
			if err := AssertUpdateDisplayNameOperationUpdateDisplayNameRequired(obj.UpdateDisplayName); err != nil {
				return err
			}
			matchesCount++
		case "createSpendingGroup":
			if err := AssertCreateSpendingGroupOperationCreateSpendingGroupRequired(obj.CreateSpendingGroup); err != nil {
				return err
			}	
			matchesCount++
		case "deleteSpendingGroup":
			if err := AssertDeleteSpendingGroupOperationDeleteSpendingGroupRequired(obj.DeleteSpendingGroup); err != nil {
				return err
			}
			matchesCount++
		case "createSpending":
			if err := AssertCreateSpendingOperationCreateSpendingRequired(obj.CreateSpending); err != nil {
				return err
			}
			matchesCount++
		case "deleteSpending":
			if err := AssertDeleteSpendingOperationDeleteSpendingRequired(obj.DeleteSpending); err != nil {
				return err
			}
			matchesCount++
		case "updateEmail":
			if err := AssertUpdateEmailOperationUpdateEmailRequired(obj.UpdateEmail); err != nil {
				return err
			}
			matchesCount++
		case "verifyEmail":
			if err := AssertVerifyEmailOperationVerifyEmailRequired(obj.VerifyEmail); err != nil {
				return err
			}
			matchesCount++
		case "uploadImage":
			if err := AssertUploadImageOperationUploadImageRequired(obj.UploadImage); err != nil {
				return err
			}
			matchesCount++
		}
	}
	if matchesCount != 1 {
		return &RequiredError{Field: "value matches to multiple operations"}
	}
	return nil
}
