package defaultController

import (
	"encoding/json"
	"fmt"
	"verni/internal/common"
	"verni/internal/controllers/operations"
	openapi "verni/internal/openapi/go"
	operationsRepository "verni/internal/repositories/operations"
	pushTokens "verni/internal/repositories/pushNotifications"
	"verni/internal/services/logging"
	"verni/internal/services/pushNotifications"
	"verni/internal/services/realtimeEvents"
)

type OperationsRepository operationsRepository.Repository

func New(
	operationsRepository OperationsRepository,
	realtimeEvents realtimeEvents.Service,
	pushNotifications pushNotifications.Service,
	pushTokensRepository pushTokens.Repository,
	logger logging.Service,
) operations.Controller {
	return &defaultController{
		operationsRepository: operationsRepository,
		realtimeEvents:       realtimeEvents,
		pushNotifications:    pushNotifications,
		pushTokensRepository: pushTokensRepository,
		logger:               logger,
	}
}

type defaultController struct {
	operationsRepository OperationsRepository
	realtimeEvents       realtimeEvents.Service
	pushNotifications    pushNotifications.Service
	pushTokensRepository pushTokens.Repository
	logger               logging.Service
}

func (c *defaultController) Push(
	operations []openapi.SomeOperation,
	userId operations.UserId,
	deviceId operations.DeviceId,
) error {
	const op = "controllers.operations.defaultController.Push"
	c.logger.LogInfo("%s: start[user=%s device=%s]", op, userId, deviceId)
	operationsToPush := common.Map(operations, func(operation openapi.SomeOperation) operationsRepository.PushOperation {
		return operationsRepository.CreateOperation(operation)
	})
	if err := c.operationsRepository.Push(
		operationsToPush,
		operationsRepository.UserId(userId),
		operationsRepository.DeviceId(deviceId),
		true,
	).Perform(); err != nil {
		return fmt.Errorf("pushing operations to repository: %w", err)
	}
	for index, operation := range operationsToPush {
		trackedEntities := operation.Payload.TrackedEntities()
		userIdsToNotify, err := c.operationsRepository.GetUsers(trackedEntities)
		if err != nil {
			c.logger.LogError("getting users to notify: %v", err)
			continue
		}
		for _, userToNotify := range userIdsToNotify {
			devicesToIgnore := []realtimeEvents.DeviceId{}
			if userToNotify == operationsRepository.UserId(userId) {
				devicesToIgnore = append(devicesToIgnore, realtimeEvents.DeviceId(deviceId))
			}
			c.logger.LogInfo("notifying %s about update, devices to ignore: %v", userToNotify, devicesToIgnore)
			c.realtimeEvents.NotifyUpdate(realtimeEvents.UserId(userToNotify), devicesToIgnore)
		}
		userToNotifyWithoutCurrentUser := common.Filter(userIdsToNotify, func(id operationsRepository.UserId) bool {
			return id != operationsRepository.UserId(userId)
		})
		switch operation.Payload.Type() {
		case operationsRepository.CreateSpendingGroupOperationPayloadType:
			if err := c.sendCreateSpendingGroupPush(
				operations[index].CreateSpendingGroup,
				userToNotifyWithoutCurrentUser,
			); err != nil {
				c.logger.LogError("sending create spending group push: %v", err)
			}
		case operationsRepository.CreateSpendingOperationPayloadType:
			if err := c.sendCreateSpendingPush(
				operations[index].CreateSpending,
				userToNotifyWithoutCurrentUser,
			); err != nil {
				c.logger.LogError("sending create spending push: %v", err)
			}
		}
	}
	c.logger.LogInfo("%s: success[user=%s device=%s]", op, userId, deviceId)
	return nil
}

func (c *defaultController) Pull(
	userId operations.UserId,
	deviceId operations.DeviceId,
	operationsType openapi.OperationType,
) ([]openapi.SomeOperation, error) {
	const op = "controllers.operations.defaultController.Pull"
	c.logger.LogInfo("%s: start[user=%s device=%s]", op, userId, deviceId)

	pulled, err := c.operationsRepository.Pull(
		operationsRepository.UserId(userId),
		operationsRepository.DeviceId(deviceId),
		func() operationsRepository.OperationType {
			switch operationsType {
			case openapi.REGULAR:
				return operationsRepository.OperationTypeRegular
			case openapi.LARGE:
				return operationsRepository.OperationTypeLarge
			default:
				return operationsRepository.OperationTypeRegular
			}
		}(),
	)
	if err != nil {
		return nil, fmt.Errorf("pulling operations from repository: %w", err)
	}

	result := make([]openapi.SomeOperation, len(pulled))
	for index, operation := range pulled {
		data, err := operation.Payload.Data()
		if err != nil {
			return nil, fmt.Errorf("getting data from operation %v: %w", operation, err)
		}
		var converted openapi.SomeOperation
		if err := json.Unmarshal(data, &converted); err != nil {
			return nil, fmt.Errorf("parsing operation from %v payload data: %w", operation, err)
		}
		result[index] = converted
	}
	c.logger.LogInfo("%s: success[user=%s device=%s]", op, userId, deviceId)
	return result, nil
}

func (c *defaultController) Confirm(
	operationIds []operations.OperationId,
	userId operations.UserId,
	deviceId operations.DeviceId,
) error {
	const op = "controllers.operations.defaultController.Confirm"
	c.logger.LogInfo("%s: start[user=%s device=%s operationsCount=%d]", op, userId, deviceId, len(operationIds))
	if err := c.operationsRepository.Confirm(
		common.Map(operationIds, func(id operations.OperationId) operationsRepository.OperationId {
			return operationsRepository.OperationId(id)
		}),
		operationsRepository.UserId(userId),
		operationsRepository.DeviceId(deviceId),
	).Perform(); err != nil {
		return fmt.Errorf("confirming operations in repository: %w", err)
	}
	c.logger.LogInfo("%s: success[user=%s device=%s operationsCount=%d]", op, userId, deviceId, len(operationIds))
	return nil
}
