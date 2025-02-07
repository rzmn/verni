package operations

import (
	openapi "verni/internal/openapi/go"
)

type OperationId string
type UserId string
type DeviceId string

type Controller interface {
	Push(operations []openapi.SomeOperation, userId UserId, deviceId DeviceId) error
	Pull(userId UserId, deviceId DeviceId, operationsType openapi.OperationType) ([]openapi.SomeOperation, error)
	Confirm(operations []OperationId, userId UserId, deviceId DeviceId) error
}
