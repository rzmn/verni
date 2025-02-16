package defaultController_test

import (
	"encoding/json"
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"verni/internal/controllers/images"
	defaultController "verni/internal/controllers/images/default"
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

func TestController_GetImages(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful get images", func(t *testing.T) {
		// Arrange
		imageId1 := images.ImageId("image-1")
		imageId2 := images.ImageId("image-2")
		base64Data1 := "base64-data-1"
		base64Data2 := "base64-data-2"

		uploadOp1 := openapi.UploadImageOperation{
			UploadImage: openapi.UploadImageOperationUploadImage{
				ImageId: string(imageId1),
				Base64:  base64Data1,
			},
		}
		uploadOp2 := openapi.UploadImageOperation{
			UploadImage: openapi.UploadImageOperationUploadImage{
				ImageId: string(imageId2),
				Base64:  base64Data2,
			},
		}

		op1Data, err := json.Marshal(uploadOp1)
		require.NoError(t, err)
		op2Data, err := json.Marshal(uploadOp2)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						Payload: mockOperationPayload{
							typeImpl: operations.UploadImageOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return op1Data, nil
							},
						},
					},
					{
						Payload: mockOperationPayload{
							typeImpl: operations.UploadImageOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return op2Data, nil
							},
						},
					},
				}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.GetImages([]images.ImageId{imageId1, imageId2})

		// Assert
		assert.NoError(t, err)
		assert.Len(t, result, 2)
		assert.Equal(t, imageId1, result[0].Id)
		assert.Equal(t, base64Data1, result[0].Base64)
		assert.Equal(t, imageId2, result[1].Id)
		assert.Equal(t, base64Data2, result[1].Base64)
	})

	t.Run("repository error", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return nil, errors.New("repository error")
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.GetImages([]images.ImageId{images.ImageId("image-1")})

		// Assert
		assert.Error(t, err)
		assert.Empty(t, result)
	})

	t.Run("skip non-image operations", func(t *testing.T) {
		// Arrange
		imageId := images.ImageId("image-1")
		base64Data := "base64-data-1"

		uploadOp := openapi.UploadImageOperation{
			UploadImage: openapi.UploadImageOperationUploadImage{
				ImageId: string(imageId),
				Base64:  base64Data,
			},
		}

		opData, err := json.Marshal(uploadOp)
		require.NoError(t, err)

		opsRepo := &operationsRepository_mock.RepositoryMock{
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						// Non-image operation
						Payload: mockOperationPayload{
							typeImpl: operations.CreateUserOperationPayloadType,
						},
					},
					{
						// Valid image operation
						Payload: mockOperationPayload{
							typeImpl: operations.UploadImageOperationPayloadType,
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
		result, err := controller.GetImages([]images.ImageId{imageId})

		// Assert
		assert.NoError(t, err)
		assert.Len(t, result, 1)
		assert.Equal(t, imageId, result[0].Id)
		assert.Equal(t, base64Data, result[0].Base64)
	})

	t.Run("payload data error", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						Payload: mockOperationPayload{
							typeImpl: operations.UploadImageOperationPayloadType,
							dataImpl: func() ([]byte, error) {
								return nil, errors.New("data error")
							},
						},
					},
				}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.GetImages([]images.ImageId{images.ImageId("image-1")})

		// Assert
		assert.Error(t, err)
		assert.Empty(t, result)
	})

	t.Run("invalid payload json", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{
					{
						Payload: mockOperationPayload{
							typeImpl: operations.UploadImageOperationPayloadType,
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
		result, err := controller.GetImages([]images.ImageId{images.ImageId("image-1")})

		// Assert
		assert.Error(t, err)
		assert.Empty(t, result)
	})

	t.Run("empty image ids", func(t *testing.T) {
		// Arrange
		opsRepo := &operationsRepository_mock.RepositoryMock{
			GetImpl: func(entities []operations.TrackedEntity) ([]operations.Operation, error) {
				return []operations.Operation{}, nil
			},
		}

		controller := defaultController.New(opsRepo, logger)

		// Act
		result, err := controller.GetImages([]images.ImageId{})

		// Assert
		assert.NoError(t, err)
		assert.Empty(t, result)
	})
}
