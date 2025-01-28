package operations

type UserId string
type DeviceId string
type OperationId string

type TrackedEntity struct {
	Id   string
	Type string
}

type Operation struct {
	Id        OperationId
	Author    UserId
	CreatedAt int64
	Payload   []byte
}

type OperationWithTrackedEntities struct {
	Operation
	TrackedEntities []TrackedEntity
}

type Repository interface {
	Push(operations []OperationWithTrackedEntities, userId UserId, deviceId DeviceId) error
	Pull(userId UserId, deviceId DeviceId) ([]Operation, error)
	Confirm(operations []OperationId, userId UserId, deviceId DeviceId) error
}
