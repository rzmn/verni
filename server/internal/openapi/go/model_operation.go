// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

type Operation struct {
	OperationId string `json:"operationId"`

	CreatedAt int64 `json:"createdAt"`

	AuthorId string `json:"authorId"`

	CreateUser CreateUserOperationCreateUser `json:"createUser"`

	BindUser BindUserOperationBindUser `json:"bindUser"`

	UpdateAvatar UpdateAvatarOperationUpdateAvatar `json:"updateAvatar"`

	UpdateDisplayName CreateUserOperationCreateUser `json:"updateDisplayName"`

	CreateSpendingGroup CreateSpendingGroupOperationCreateSpendingGroup `json:"createSpendingGroup"`

	DeleteSpendingGroup DeleteSpendingGroupOperationDeleteSpendingGroup `json:"deleteSpendingGroup"`

	CreateSpending CreateSpendingOperationCreateSpending `json:"createSpending"`

	DeleteSpending DeleteSpendingOperationDeleteSpending `json:"deleteSpending"`

	UpdateEmail UpdateEmailRequest `json:"updateEmail"`

	VerifyEmail VerifyEmailOperationVerifyEmail `json:"verifyEmail"`

	UploadImage UploadImageOperationUploadImage `json:"uploadImage"`
}

// AssertOperationRequired checks if the required fields are not zero-ed
func AssertOperationRequired(obj Operation) error {
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
	for name, el := range elements {
		if isZero := IsZeroValue(el); isZero {
			return &RequiredError{Field: name}
		}
	}

	if err := AssertCreateUserOperationCreateUserRequired(obj.CreateUser); err != nil {
		return err
	}
	if err := AssertBindUserOperationBindUserRequired(obj.BindUser); err != nil {
		return err
	}
	if err := AssertUpdateAvatarOperationUpdateAvatarRequired(obj.UpdateAvatar); err != nil {
		return err
	}
	if err := AssertCreateUserOperationCreateUserRequired(obj.UpdateDisplayName); err != nil {
		return err
	}
	if err := AssertCreateSpendingGroupOperationCreateSpendingGroupRequired(obj.CreateSpendingGroup); err != nil {
		return err
	}
	if err := AssertDeleteSpendingGroupOperationDeleteSpendingGroupRequired(obj.DeleteSpendingGroup); err != nil {
		return err
	}
	if err := AssertCreateSpendingOperationCreateSpendingRequired(obj.CreateSpending); err != nil {
		return err
	}
	if err := AssertDeleteSpendingOperationDeleteSpendingRequired(obj.DeleteSpending); err != nil {
		return err
	}
	if err := AssertUpdateEmailRequestRequired(obj.UpdateEmail); err != nil {
		return err
	}
	if err := AssertVerifyEmailOperationVerifyEmailRequired(obj.VerifyEmail); err != nil {
		return err
	}
	if err := AssertUploadImageOperationUploadImageRequired(obj.UploadImage); err != nil {
		return err
	}
	return nil
}

// AssertOperationConstraints checks if the values respects the defined constraints
func AssertOperationConstraints(obj Operation) error {
	if err := AssertCreateUserOperationCreateUserConstraints(obj.CreateUser); err != nil {
		return err
	}
	if err := AssertBindUserOperationBindUserConstraints(obj.BindUser); err != nil {
		return err
	}
	if err := AssertUpdateAvatarOperationUpdateAvatarConstraints(obj.UpdateAvatar); err != nil {
		return err
	}
	if err := AssertCreateUserOperationCreateUserConstraints(obj.UpdateDisplayName); err != nil {
		return err
	}
	if err := AssertCreateSpendingGroupOperationCreateSpendingGroupConstraints(obj.CreateSpendingGroup); err != nil {
		return err
	}
	if err := AssertDeleteSpendingGroupOperationDeleteSpendingGroupConstraints(obj.DeleteSpendingGroup); err != nil {
		return err
	}
	if err := AssertCreateSpendingOperationCreateSpendingConstraints(obj.CreateSpending); err != nil {
		return err
	}
	if err := AssertDeleteSpendingOperationDeleteSpendingConstraints(obj.DeleteSpending); err != nil {
		return err
	}
	if err := AssertUpdateEmailRequestConstraints(obj.UpdateEmail); err != nil {
		return err
	}
	if err := AssertVerifyEmailOperationVerifyEmailConstraints(obj.VerifyEmail); err != nil {
		return err
	}
	if err := AssertUploadImageOperationUploadImageConstraints(obj.UploadImage); err != nil {
		return err
	}
	return nil
}
