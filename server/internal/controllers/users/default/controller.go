package defaultController

import (
	"encoding/json"
	"fmt"
	"verni/internal/controllers/users"
	openapi "verni/internal/openapi/go"
	operationsRepository "verni/internal/repositories/operations"
	"verni/internal/services/logging"
)

type OperationsRepository operationsRepository.Repository

func New(
	operationsRepository OperationsRepository,
	logger logging.Service,
) users.Controller {
	return &defaultController{
		operationsRepository: operationsRepository,
		logger:               logger,
	}
}

type defaultController struct {
	operationsRepository OperationsRepository
	logger               logging.Service
}

type UserId string

func (c *defaultController) Search(query string) ([]openapi.SomeOperation, error) {
	const op = "users.defaultController.Search"
	c.logger.LogInfo("%s: start[q=%s]", op, query)
	if len(query) == 0 {
		c.logger.LogInfo("%s: success[q=%s]", op, query)
		return []openapi.SomeOperation{}, nil
	}
	createOperations, err := c.getCreateUserOperations(query)
	if err != nil {
		err := fmt.Errorf("getting create operations: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return []openapi.SomeOperation{}, err
	}
	updateDisplayNameOperations, err := c.getUpdateDisplayNameOperations(query)
	if err != nil {
		err := fmt.Errorf("getting update display name operations: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return []openapi.SomeOperation{}, err
	}
	displayNames := map[UserId]string{}
	for _, operation := range createOperations {
		displayNames[UserId(operation.UserId)] = operation.DisplayName
	}
	for _, operation := range updateDisplayNameOperations {
		displayNames[UserId(operation.UserId)] = operation.DisplayName
	}
	entities := make([]operationsRepository.TrackedEntity, 0, len(displayNames))
	for userId := range displayNames {
		entities = append(
			entities,
			operationsRepository.TrackedEntity{
				Type: operationsRepository.EntityTypeUser,
				Id:   string(userId),
			},
		)
	}
	if len(entities) == 0 {
		c.logger.LogInfo("%s: success[q=%s]", op, query)
		return []openapi.SomeOperation{}, nil
	}
	operations, err := c.operationsRepository.Get(entities)
	if err != nil {
		err := fmt.Errorf("getting operations affecting selected users: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return []openapi.SomeOperation{}, err
	}
	result := []openapi.SomeOperation{}
	for _, operation := range operations {
		data, err := operation.Payload.Data()
		if err != nil {
			err := fmt.Errorf("getting operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []openapi.SomeOperation{}, err
		}
		var openapiOperation openapi.SomeOperation
		if err := json.Unmarshal(data, &openapiOperation); err != nil {
			err := fmt.Errorf("decoding operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []openapi.SomeOperation{}, err
		}
		result = append(result, openapiOperation)
	}
	return result, nil
}

func (c *defaultController) getCreateUserOperations(query string) ([]openapi.CreateUserOperationCreateUser, error) {
	const op = "users.defaultController.getCreateUserOperations"
	c.logger.LogInfo("%s: start[q=%s]", op, query)
	operations, err := c.operationsRepository.Search(
		operationsRepository.CreateUserOperationPayloadType,
		query,
	)
	if err != nil {
		err := fmt.Errorf("getting create operations (db): %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return []openapi.CreateUserOperationCreateUser{}, err
	}
	result := []openapi.CreateUserOperationCreateUser{}
	for _, operation := range operations {
		if operation.Payload.Type() != operationsRepository.CreateUserOperationPayloadType {
			c.logger.LogInfo("%s: unexpected operation type %s, skipping", op, operation.Payload.Type())
			continue
		}
		data, err := operation.Payload.Data()
		if err != nil {
			err := fmt.Errorf("getting operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []openapi.CreateUserOperationCreateUser{}, err
		}
		var createUserOperation openapi.SomeOperation
		if err := json.Unmarshal(data, &createUserOperation); err != nil {
			err := fmt.Errorf("decoding operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []openapi.CreateUserOperationCreateUser{}, err
		}
		result = append(result, createUserOperation.CreateUser)
	}
	c.logger.LogInfo("%s: success[q=%s]", op, query)
	return result, nil
}

func (c *defaultController) getUpdateDisplayNameOperations(query string) ([]openapi.UpdateDisplayNameOperationUpdateDisplayName, error) {
	const op = "users.defaultController.getUpdateDisplayNameOperations"
	c.logger.LogInfo("%s: start[q=%s]", op, query)
	operations, err := c.operationsRepository.Search(
		operationsRepository.UpdateDisplayNameOperationPayloadType,
		query,
	)
	if err != nil {
		err := fmt.Errorf("getting update display name operations (db): %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return []openapi.UpdateDisplayNameOperationUpdateDisplayName{}, err
	}
	result := []openapi.UpdateDisplayNameOperationUpdateDisplayName{}
	for _, operation := range operations {
		if operation.Payload.Type() != operationsRepository.UpdateDisplayNameOperationPayloadType {
			c.logger.LogInfo("%s: unexpected operation type %s, skipping", op, operation.Payload.Type())
			continue
		}
		data, err := operation.Payload.Data()
		if err != nil {
			err := fmt.Errorf("getting operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []openapi.UpdateDisplayNameOperationUpdateDisplayName{}, err
		}
		var updateDisplayNameOperation openapi.SomeOperation
		if err := json.Unmarshal(data, &updateDisplayNameOperation); err != nil {
			err := fmt.Errorf("decoding operation payload: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return []openapi.UpdateDisplayNameOperationUpdateDisplayName{}, err
		}
		result = append(result, updateDisplayNameOperation.UpdateDisplayName)
	}
	c.logger.LogInfo("%s: success[q=%s]", op, query)
	return result, nil
}
