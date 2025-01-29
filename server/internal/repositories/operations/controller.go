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
	CreatedAt   int64
	OperationId OperationId
	AuthorId    UserId
	Payload     OperationPayload
}

type Repository interface {
	Push(operations []Operation, userId UserId, deviceId DeviceId) repositories.Transaction
	Pull(userId UserId, deviceId DeviceId) ([]Operation, error)
	Confirm(operations []OperationId, userId UserId, deviceId DeviceId) repositories.Transaction
}

const (
	CreateUserOperationPayloadType = "CreateUser"
	UnknownOperationPayloadType    = "Unknown"
)

const (
	EntityTypeUser = "User"
)

var (
	BadOperation = errors.New("bad operation")
)

type OperationPayload interface {
	Type() string
	Data() ([]byte, error)
	TrackedEntities() []TrackedEntity
}
