package operations

import (
	"errors"
	"verni/internal/repositories"
)

type UserId string
type DeviceId string
type OperationId string

var (
	ErrBadOperation = errors.New("bad operation")
	ErrConflict     = errors.New("operation identifier is already taken")
)

type Repository interface {
	Push(operations []PushOperation, userId UserId, deviceId DeviceId, confirm bool) repositories.UnitOfWork
	Pull(userId UserId, deviceId DeviceId, operationType OperationType) ([]Operation, error)
	Confirm(operations []OperationId, userId UserId, deviceId DeviceId) repositories.UnitOfWork

	GetUsers(trackingEntities []TrackedEntity) ([]UserId, error)
	Get(affectingEntities []TrackedEntity) ([]Operation, error)
	Search(payloadType OperationPayloadType, hint string) ([]Operation, error)
}
