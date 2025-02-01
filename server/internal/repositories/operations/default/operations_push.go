package defaultRepository

import (
	"context"
	"database/sql"
	"fmt"
	"verni/internal/repositories/operations"
)

func (c *defaultRepository) push(
	operations []operations.Operation,
	userId operations.UserId,
	deviceId operations.DeviceId,
) error {
	const op = "repositories.operations.defaultRepository.push"
	c.logger.LogInfo("%s: start[user=%s device=%s]", op, userId, deviceId)

	tx, err := c.db.BeginTx(context.Background(), nil)
	if err != nil {
		return fmt.Errorf("%s: failed to begin transaction: %w", op, err)
	}
	defer func() {
		if err != nil {
			tx.Rollback()
		} else {
			err = tx.Commit()
		}
	}()

	for _, operation := range operations {
		if err := insertOperation(tx, operation); err != nil {
			return err
		}

		for _, entity := range operation.Payload.TrackedEntities() {
			if err := insertEntity(tx, operation.OperationId, entity); err != nil {
				return err
			}
			if err := insertTrackedEntity(tx, userId, entity); err != nil {
				return err
			}
		}

		if err := insertConfirmedOperation(tx, userId, deviceId, operation.OperationId); err != nil {
			return err
		}
	}

	c.logger.LogInfo("%s: success[user=%s device=%s]", op, userId, deviceId)
	return nil
}

func insertOperation(tx *sql.Tx, operation operations.Operation) error {
	query := `
INSERT INTO operations (operationId, createdAt, authorId, operationType, isLarge, data, searchHint)
VALUES ($1, $2, $3, $4, $5, $6, $7);`

	data, _ := operation.Payload.Data()
	if _, err := tx.Exec(query,
		operation.OperationId,
		operation.CreatedAt,
		operation.AuthorId,
		operation.Payload.Type(),
		operation.Payload.IsLarge(),
		data,
		operation.Payload.SearchHint(),
	); err != nil {
		return fmt.Errorf("failed to insert operation %s: %w", operation.OperationId, err)
	}
	return nil
}

func insertEntity(tx *sql.Tx, operationId operations.OperationId, entity operations.TrackedEntity) error {
	query := `
INSERT INTO operationsAffectingEntity (operationId, entityId, entityType)
VALUES ($1, $2, $3);`

	if _, err := tx.Exec(query,
		operationId,
		entity.Id,
		entity.Type,
	); err != nil {
		return fmt.Errorf("failed to insert entity for operation %s: %w", operationId, err)
	}
	return nil
}

func insertTrackedEntity(tx *sql.Tx, userId operations.UserId, entity operations.TrackedEntity) error {
	query := `
INSERT INTO trackedEntities (userId, entityId, entityType)
VALUES ($1, $2, $3);`

	if _, err := tx.Exec(query,
		userId,
		entity.Id,
		entity.Type,
	); err != nil {
		return fmt.Errorf("failed to insert tracked entity for user %s: %w", userId, err)
	}
	return nil
}

func insertConfirmedOperation(tx *sql.Tx, userId operations.UserId, deviceId operations.DeviceId, operationId operations.OperationId) error {
	query := `
INSERT INTO confirmedOperations (userId, deviceId, operationId)
VALUES ($1, $2, $3);`

	if _, err := tx.Exec(query,
		userId,
		deviceId,
		operationId,
	); err != nil {
		return fmt.Errorf("failed to insert confirmed operation for user %s: %w", userId, err)
	}
	return nil
}
