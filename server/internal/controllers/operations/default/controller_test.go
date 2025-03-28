package defaultController_test

import (
	"encoding/json"
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"verni/internal/controllers/operations"
	defaultController "verni/internal/controllers/operations/default"
	openapi "verni/internal/openapi/go"
	"verni/internal/repositories"
	operationsRepository "verni/internal/repositories/operations"
	operationsRepository_mock "verni/internal/repositories/operations/mock"
	pushNotifications "verni/internal/repositories/pushNotifications"
	pushNotifications_mock "verni/internal/repositories/pushNotifications/mock"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
	pushTokens "verni/internal/services/pushNotifications"
	pushTokens_mock "verni/internal/services/pushNotifications/mock"
	realtimeEvents "verni/internal/services/realtimeEvents"
	realtimeEvents_mock "verni/internal/services/realtimeEvents/mock"
)

// Mock implementation of OperationPayload interface
type mockOperationPayload struct {
	typeImpl            operationsRepository.OperationPayloadType
	dataImpl            func() ([]byte, error)
	trackedEntitiesImpl []operationsRepository.TrackedEntity
	isLargeImpl         bool
	searchHintImpl      *string
}

func (m mockOperationPayload) Type() operationsRepository.OperationPayloadType {
	return m.typeImpl
}

func (m mockOperationPayload) Data() ([]byte, error) {
	return m.dataImpl()
}

func (m mockOperationPayload) TrackedEntities() []operationsRepository.TrackedEntity {
	return m.trackedEntitiesImpl
}

func (m mockOperationPayload) IsLarge() bool {
	return m.isLargeImpl
}

func (m mockOperationPayload) SearchHint() *string {
	return m.searchHintImpl
}

func TestController_Push(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful push", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")

		testOperation := openapi.SomeOperation{
			OperationId: "op-1",
			CreatedAt:   time.Now().UnixMilli(),
			AuthorId:    "test-user",
			CreateUser: openapi.CreateUserOperationCreateUser{
				UserId:      "test-user",
				DisplayName: "Test User",
			},
		}

		opsRepo := &operationsRepository_mock.RepositoryMock{
			PushImpl: func(ops []operationsRepository.PushOperation, uid operationsRepository.UserId, did operationsRepository.DeviceId, confirm bool) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
			GetUsersImpl: func(entities []operationsRepository.TrackedEntity) ([]operationsRepository.UserId, error) {
				return []operationsRepository.UserId{operationsRepository.UserId(userId)}, nil
			},
		}

		realtimeService := &realtimeEvents_mock.ServiceMock{
			NotifyUpdateImpl: func(uid realtimeEvents.UserId, ignoringDevices []realtimeEvents.DeviceId) {},
		}

		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, realtimeService, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		err := controller.Push([]openapi.SomeOperation{testOperation}, userId, deviceId)

		// Assert
		assert.NoError(t, err)
	})

	t.Run("repository push error", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			PushImpl: func(ops []operationsRepository.PushOperation, uid operationsRepository.UserId, did operationsRepository.DeviceId, confirm bool) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return errors.New("push error") },
					Rollback: func() error { return nil },
				}
			},
		}
		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, nil, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		err := controller.Push([]openapi.SomeOperation{}, "user-1", "device-1")

		// Assert
		assert.Error(t, err)
	})
}

func TestController_Pull(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful pull regular operations", func(t *testing.T) {
		// Arrange
		testOperation := openapi.SomeOperation{
			OperationId: "op-1",
			CreatedAt:   time.Now().UnixMilli(),
			AuthorId:    "test-user",
			CreateUser: openapi.CreateUserOperationCreateUser{
				UserId:      "test-user",
				DisplayName: "Test User",
			},
		}

		operationData, err := json.Marshal(testOperation)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			PullImpl: func(uid operationsRepository.UserId, did operationsRepository.DeviceId, opType operationsRepository.OperationType) ([]operationsRepository.Operation, error) {
				return []operationsRepository.Operation{
					{
						OperationId: "op-1",
						CreatedAt:   time.Now().UnixMilli(),
						AuthorId:    "test-user",
						Payload: mockOperationPayload{
							dataImpl: func() ([]byte, error) {
								return operationData, nil
							},
						},
					},
				}, nil
			},
		}
		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, nil, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		result, err := controller.Pull("user-1", "device-1", openapi.REGULAR)

		// Assert
		assert.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, testOperation.OperationId, result[0].OperationId)
	})

	t.Run("repository pull error", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			PullImpl: func(uid operationsRepository.UserId, did operationsRepository.DeviceId, opType operationsRepository.OperationType) ([]operationsRepository.Operation, error) {
				return nil, errors.New("pull error")
			},
		}
		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, nil, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		result, err := controller.Pull("user-1", "device-1", openapi.REGULAR)

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
	})

	t.Run("invalid operation payload", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			PullImpl: func(uid operationsRepository.UserId, did operationsRepository.DeviceId, opType operationsRepository.OperationType) ([]operationsRepository.Operation, error) {
				return []operationsRepository.Operation{
					{
						OperationId: "op-1",
						CreatedAt:   time.Now().UnixMilli(),
						AuthorId:    "test-user",
						Payload: mockOperationPayload{
							dataImpl: func() ([]byte, error) {
								return []byte("invalid json"), nil
							},
						},
					},
				}, nil
			},
		}
		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, nil, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		result, err := controller.Pull("user-1", "device-1", openapi.REGULAR)

		// Assert
		assert.Error(t, err)
		assert.Nil(t, result)
	})
}

func TestController_Confirm(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful confirm", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			ConfirmImpl: func(ops []operationsRepository.OperationId, uid operationsRepository.UserId, did operationsRepository.DeviceId) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}
		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, nil, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		err := controller.Confirm([]operations.OperationId{"op-1"}, "user-1", "device-1")

		// Assert
		assert.NoError(t, err)
	})

	t.Run("repository confirm error", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			ConfirmImpl: func(ops []operationsRepository.OperationId, uid operationsRepository.UserId, did operationsRepository.DeviceId) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return errors.New("confirm error") },
					Rollback: func() error { return nil },
				}
			},
		}
		pushNotificationsRepository := &pushNotifications_mock.RepositoryMock{
			GetPushTokensImpl: func(userIds []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
				return map[pushNotifications.UserId][]string{}, nil
			},
		}
		pushNotificationsService := &pushTokens_mock.ServiceMock{
			AlertImpl: func(token pushTokens.Token, title string, subtitle *string, body *string, data interface{}) error {
				return nil
			},
		}

		controller := defaultController.New(opsRepo, nil, pushNotificationsService, pushNotificationsRepository, logger)

		// Act
		err := controller.Confirm([]operations.OperationId{"op-1"}, "user-1", "device-1")

		// Assert
		assert.Error(t, err)
	})
}
