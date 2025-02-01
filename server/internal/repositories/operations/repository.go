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

type Repository interface {
	Push(operations []Operation, userId UserId, deviceId DeviceId) repositories.Transaction
	Pull(userId UserId, deviceId DeviceId, ignoreLargeOperations bool) ([]Operation, error)
	Confirm(operations []OperationId, userId UserId, deviceId DeviceId) repositories.Transaction

	Get(affectingEntities []TrackedEntity) ([]Operation, error)
	Search(payloadType string, hint string) ([]Operation, error)
}

const (
	CreateUserOperationPayloadType        = "CreateUser"
	UpdateDisplayNameOperationPayloadType = "UpdateDisplayName"
	UploadImageOperationPayloadType       = "UploadImage"
	UnknownOperationPayloadType           = "Unknown"
)

const (
	EntityTypeUser  = "User"
	EntityTypeImage = "Image"
)

var (
	BadOperation = errors.New("bad operation")
	Conflict     = errors.New("operation identifier is already taken")
)

type OperationPayload interface {
	Type() string
	Data() ([]byte, error)
	TrackedEntities() []TrackedEntity
	IsLarge() bool
	SearchHint() *string
}
