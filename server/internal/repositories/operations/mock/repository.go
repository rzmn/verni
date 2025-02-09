package operations_mock

import (
	"verni/internal/repositories"
	"verni/internal/repositories/operations"
)

type RepositoryMock struct {
	PushImpl    func(operations []operations.PushOperation, userId operations.UserId, deviceId operations.DeviceId, confirm bool) repositories.UnitOfWork
	PullImpl    func(userId operations.UserId, deviceId operations.DeviceId, ignoreLargeOperations bool) ([]operations.Operation, error)
	ConfirmImpl func(operations []operations.OperationId, userId operations.UserId, deviceId operations.DeviceId) repositories.UnitOfWork
	GetImpl     func(affectingEntities []operations.TrackedEntity) ([]operations.Operation, error)
	SearchImpl  func(payloadType string, hint string) ([]operations.Operation, error)
}

func (r *RepositoryMock) Push(operations []operations.PushOperation, userId operations.UserId, deviceId operations.DeviceId, confirm bool) repositories.UnitOfWork {
	return r.PushImpl(operations, userId, deviceId, confirm)
}

func (r *RepositoryMock) Pull(userId operations.UserId, deviceId operations.DeviceId, ignoreLargeOperations bool) ([]operations.Operation, error) {
	return r.PullImpl(userId, deviceId, ignoreLargeOperations)
}

func (r *RepositoryMock) Confirm(operations []operations.OperationId, userId operations.UserId, deviceId operations.DeviceId) repositories.UnitOfWork {
	return r.ConfirmImpl(operations, userId, deviceId)
}

func (r *RepositoryMock) Get(affectingEntities []operations.TrackedEntity) ([]operations.Operation, error) {
	return r.GetImpl(affectingEntities)
}

func (r *RepositoryMock) Search(payloadType string, hint string) ([]operations.Operation, error) {
	return r.SearchImpl(payloadType, hint)
}
