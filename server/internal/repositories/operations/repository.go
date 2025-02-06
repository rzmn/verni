package operations

import (
	"errors"
	"verni/internal/repositories"
)

type UserId string
type DeviceId string
type OperationId string

type TrackedEntity struct {
	Id   string
	Type string
}

type Operation struct {
	OperationId OperationId
	CreatedAt   int64
	AuthorId    UserId
	Payload     OperationPayload
}

type PushOperation struct {
	Operation
	EntityBindActions []EntityBindAction
}

type Repository interface {
	Push(operations []PushOperation, userId UserId, deviceId DeviceId, confirm bool) repositories.Transaction
	Pull(userId UserId, deviceId DeviceId, ignoreLargeOperations bool) ([]Operation, error)
	Confirm(operations []OperationId, userId UserId, deviceId DeviceId) repositories.Transaction

	Get(affectingEntities []TrackedEntity) ([]Operation, error)
	Search(payloadType string, hint string) ([]Operation, error)
}

var (
	ErrBadOperation = errors.New("bad operation")
	ErrConflict     = errors.New("operation identifier is already taken")
)

const (
	CreateUserOperationPayloadType          = "CreateUser"
	UpdateDisplayNameOperationPayloadType   = "UpdateDisplayName"
	UploadImageOperationPayloadType         = "UploadImage"
	BindUserOperationPayloadType            = "BindUser"
	UpdateAvatarOperationPayloadType        = "UpdateAvatar"
	CreateSpendingGroupOperationPayloadType = "CreateSpendingGroup"
	DeleteSpendingGroupOperationPayloadType = "DeleteSpendingGroup"
	CreateSpendingOperationPayloadType      = "CreateSpending"
	DeleteSpendingOperationPayloadType      = "DeleteSpending"
	UpdateEmailOperationPayloadType         = "UpdateEmail"
	VerifyEmailOperationPayloadType         = "VerifyEmail"
	UnknownOperationPayloadType             = "Unknown"
)

const (
	EntityTypeUser          = "User"
	EntityTypeImage         = "Image"
	EntityTypeSpendingGroup = "SpendingGroup"
)

type EntityBindAction struct {
	Watchers []UserId
	Entity   TrackedEntity
}

type OperationPayload interface {
	Type() string
	Data() ([]byte, error)
	TrackedEntities() []TrackedEntity
	IsLarge() bool
	SearchHint() *string
}
