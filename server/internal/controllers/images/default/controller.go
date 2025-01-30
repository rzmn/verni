package defaultController

import (
	"encoding/json"
	"fmt"
	"verni/internal/common"
	"verni/internal/controllers/images"
	openapi "verni/internal/openapi/go"
	operationsRepository "verni/internal/repositories/operations"
	"verni/internal/services/logging"
)

type OperationsRepository operationsRepository.Repository

func New(
	operationsRepository OperationsRepository,
	logger logging.Service,
) images.Controller {
	return &defaultController{
		operationsRepository: operationsRepository,
		logger:               logger,
	}
}

type defaultController struct {
	operationsRepository OperationsRepository
	logger               logging.Service
}

func (c *defaultController) GetImages(ids []images.ImageId) ([]images.Image, error) {
	const op = "avatars.defaultController.GetAvatars"
	c.logger.LogInfo("%s: start[ids=%s]", op, ids)
	operations, err := c.operationsRepository.Get(
		common.Map(
			ids,
			func(id images.ImageId) operationsRepository.TrackedEntity {
				return operationsRepository.TrackedEntity{
					Id:   string(id),
					Type: operationsRepository.EntityTypeImage,
				}
			},
		),
	)
	if err != nil {
		err := fmt.Errorf("getting corresponding operations: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return []images.Image{}, err
	}
	result := []images.Image{}
	for _, operation := range operations {
		if operation.Payload.Type() != operationsRepository.UploadImageOperationPayloadType {
			c.logger.LogInfo("%s: unexpected operation type %s, skipping", op, operation.Payload.Type())
			continue
		}
		data, err := operation.Payload.Data()
		if err != nil {
			err := fmt.Errorf("getting operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []images.Image{}, err
		}
		var uploadOperation openapi.UploadImageOperation
		if err := json.Unmarshal(data, &uploadOperation); err != nil {
			err := fmt.Errorf("decoding operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []images.Image{}, err
		}
		result = append(
			result,
			images.Image{
				Id:     images.ImageId(uploadOperation.UploadImage.ImageId),
				Base64: uploadOperation.UploadImage.Base64,
			},
		)
	}
	c.logger.LogInfo("%s: success[ids=%s]", op, ids)
	return result, nil
}
