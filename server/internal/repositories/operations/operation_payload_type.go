package operations

type OperationPayloadType string

const (
	CreateUserOperationPayloadType          OperationPayloadType = "CreateUser"
	UpdateDisplayNameOperationPayloadType   OperationPayloadType = "UpdateDisplayName"
	UploadImageOperationPayloadType         OperationPayloadType = "UploadImage"
	BindUserOperationPayloadType            OperationPayloadType = "BindUser"
	UpdateAvatarOperationPayloadType        OperationPayloadType = "UpdateAvatar"
	CreateSpendingGroupOperationPayloadType OperationPayloadType = "CreateSpendingGroup"
	DeleteSpendingGroupOperationPayloadType OperationPayloadType = "DeleteSpendingGroup"
	CreateSpendingOperationPayloadType      OperationPayloadType = "CreateSpending"
	DeleteSpendingOperationPayloadType      OperationPayloadType = "DeleteSpending"
	UpdateEmailOperationPayloadType         OperationPayloadType = "UpdateEmail"
	VerifyEmailOperationPayloadType         OperationPayloadType = "VerifyEmail"
	UnknownOperationPayloadType             OperationPayloadType = "Unknown"
)
