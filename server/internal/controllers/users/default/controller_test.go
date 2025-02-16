package defaultController_test

import (
	"encoding/json"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	defaultController "verni/internal/controllers/users/default"
	openapi "verni/internal/openapi/go"
	"verni/internal/repositories/operations"
	operationsRepository_mock "verni/internal/repositories/operations/mock"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
)

// Mock implementation of OperationPayload interface
type mockOperationPayload struct {
	typeImpl            operations.OperationPayloadType
	dataImpl            func() ([]byte, error)
	trackedEntitiesImpl []operations.TrackedEntity
	isLargeImpl         bool
	searchHintImpl      *string
}

func (m mockOperationPayload) Type() operations.OperationPayloadType {
	return m.typeImpl
}

func (m mockOperationPayload) Data() ([]byte, error) {
	return m.dataImpl()
}

func (m mockOperationPayload) TrackedEntities() []operations.TrackedEntity {
	return m.trackedEntitiesImpl
}

func (m mockOperationPayload) IsLarge() bool {
	return m.isLargeImpl
}

func (m mockOperationPayload) SearchHint() *string {
	return m.searchHintImpl
}

func TestController_Search(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("empty query returns empty result", func(t *testing.T) {
		// Arrange
		controller := defaultController.New(nil, logger)

		// Act
		result, err := controller.Search("")

		// Assert
		assert.NoError(t, err)
		assert.Empty(t, result)
	})

	t.Run("successful search with create user operations", func(t *testing.T) {
		// Arrange
		createUserOp := openapi.SomeOperation{
			OperationId: "op-1",
			CreateUser: openapi.CreateUserOperationCreateUser{
				UserId:      "user-1",
				DisplayName: "Test User",
			},
		}
		opData, err := json.Marshal(createUserOp)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			SearchImpl: func(payloadType operations.OperationPayloadType, hint string) ([]operations.Operation, error) {
				if payloadType == operations.CreateUserOperationPayloadType {
					return []operations.Operation{
						{
							OperationId: "op-1",
							Payload: mockOperationPayload{
								typeImpl: operations.CreateUserOperationPayloadType,
								dataImpl: func() ([]byte, error) {
									return opData, nil
								},
							},
						},
					}, nil
				}
				return []operations.Operation{}, nil
			},
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						OperationId: "op-1",
						Payload: mockOperationPayload{
							typeImpl: operations.CreateUserOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return opData, nil
							},
						},
					},
				}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.Search("Test")

		// Assert
		assert.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, createUserOp.OperationId, result[0].OperationId)
		assert.Equal(t, createUserOp.CreateUser.UserId, result[0].CreateUser.UserId)
		assert.Equal(t, createUserOp.CreateUser.DisplayName, result[0].CreateUser.DisplayName)
	})

	t.Run("successful search with update display name operations", func(t *testing.T) {
		// Arrange
		updateDisplayNameOp := openapi.SomeOperation{
			OperationId: "op-1",
			UpdateDisplayName: openapi.UpdateDisplayNameOperationUpdateDisplayName{
				UserId:      "user-1",
				DisplayName: "Updated Name",
			},
		}
		opData, err := json.Marshal(updateDisplayNameOp)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			SearchImpl: func(payloadType operations.OperationPayloadType, hint string) ([]operations.Operation, error) {
				if payloadType == operations.UpdateDisplayNameOperationPayloadType {
					return []operations.Operation{
						{
							OperationId: "op-1",
							Payload: mockOperationPayload{
								typeImpl: operations.UpdateDisplayNameOperationPayloadType,
								dataImpl: func() ([]byte, error) {
									return opData, nil
								},
							},
						},
					}, nil
				}
				return []operations.Operation{}, nil
			},
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						OperationId: "op-1",
						Payload: mockOperationPayload{
							typeImpl: operations.UpdateDisplayNameOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return opData, nil
							},
						},
					},
				}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.Search("Updated")

		// Assert
		assert.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, updateDisplayNameOp.OperationId, result[0].OperationId)
		assert.Equal(t, updateDisplayNameOp.UpdateDisplayName.UserId, result[0].UpdateDisplayName.UserId)
		assert.Equal(t, updateDisplayNameOp.UpdateDisplayName.DisplayName, result[0].UpdateDisplayName.DisplayName)
	})

	t.Run("search repository error", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			SearchImpl: func(payloadType operations.OperationPayloadType, hint string) ([]operations.Operation, error) {
				return nil, errors.New("search error")
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.Search("query")

		// Assert
		assert.Error(t, err)
		assert.Empty(t, result)
	})

	t.Run("get operations error", func(t *testing.T) {
		// Arrange
		createUserOp := openapi.SomeOperation{
			OperationId: "op-1",
			CreateUser: openapi.CreateUserOperationCreateUser{
				UserId:      "user-1",
				DisplayName: "Test User",
			},
		}
		opData, err := json.Marshal(createUserOp)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			SearchImpl: func(payloadType operations.OperationPayloadType, hint string) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						OperationId: "op-1",
						Payload: mockOperationPayload{
							typeImpl: operations.CreateUserOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return opData, nil
							},
						},
					},
				}, nil
			},
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return nil, errors.New("get error")
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.Search("Test")

		// Assert
		assert.Error(t, err)
		assert.Empty(t, result)
	})

	t.Run("invalid operation payload", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			SearchImpl: func(payloadType operations.OperationPayloadType, hint string) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						OperationId: "op-1",
						Payload: mockOperationPayload{
							typeImpl: operations.CreateUserOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return []byte("invalid json"), nil
							},
						},
					},
				}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.Search("Test")

		// Assert
		assert.Error(t, err)
		assert.Empty(t, result)
	})

	t.Run("skip unexpected operation types", func(t *testing.T) {
		// Arrange
		createUserOp := openapi.SomeOperation{
			OperationId: "op-1",
			CreateUser: openapi.CreateUserOperationCreateUser{
				UserId:      "user-1",
				DisplayName: "Test User",
			},
		}
		opData, err := json.Marshal(createUserOp)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			SearchImpl: func(payloadType operations.OperationPayloadType, hint string) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						OperationId: "op-1",
						Payload: mockOperationPayload{
							typeImpl: operations.UploadImageOperationPayloadType, // Unexpected type
							dataImpl: func() ([]byte, error) {
								return opData, nil
							},
						},
					},
				}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.Search("Test")

		// Assert
		assert.NoError(t, err)
		assert.Empty(t, result)
	})
}
