package defaultRepository

import (
	"context"
	"database/sql"
	"fmt"
	"verni/internal/repositories/operations"
)

func (c *defaultRepository) pushRollback(
	operations []operations.Operation,
	userId operations.UserId,
	deviceId operations.DeviceId,
) error {
	const op = "repositories.operations.defaultRepository.pushRollback"
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
		if err := deleteConfirmedOperation(tx, userId, deviceId, operation.OperationId); err != nil {
			return err
		}

		if err := deleteEntities(tx, operation.OperationId); err != nil {
			return err
		}

		if err := deleteOperation(tx, operation.OperationId); err != nil {
			return err
		}

		for _, entity := range operation.Payload.TrackedEntities() {
			if err := deleteTrackedEntity(tx, userId, entity); err != nil {
				return err
			}
		}
	}

	c.logger.LogInfo("%s: success[user=%s device=%s]", op, userId, deviceId)
	return nil
}

func deleteConfirmedOperation(tx *sql.Tx, userId operations.UserId, deviceId operations.DeviceId, operationId operations.OperationId) error {
	query := `
DELETE FROM confirmedOperations
WHERE userId = $1 AND deviceId = $2 AND operationId = $3;`

	if _, err := tx.Exec(query, userId, deviceId, operationId); err != nil {
		return fmt.Errorf("failed to delete confirmed operation for user %s: %w", userId, err)
	}
	return nil
}

func deleteEntities(tx *sql.Tx, operationId operations.OperationId) error {
	query := `
DELETE FROM operationsAffectingEntity
WHERE operationId = $1;`

	if _, err := tx.Exec(query, operationId); err != nil {
		return fmt.Errorf("failed to delete entities for operation %s: %w", operationId, err)
	}
	return nil
}

func deleteOperation(tx *sql.Tx, operationId operations.OperationId) error {
	query := `
DELETE FROM operations
WHERE operationId = $1;`

	if _, err := tx.Exec(query, operationId); err != nil {
		return fmt.Errorf("failed to delete operation %s: %w", operationId, err)
	}
	return nil
}

func deleteTrackedEntity(tx *sql.Tx, userId operations.UserId, entity operations.TrackedEntity) error {
	query := `
DELETE FROM trackedEntities
WHERE userId = $1 AND entityId = $2 AND entityType = $3;`

	if _, err := tx.Exec(query, userId, entity.Id, entity.Type); err != nil {
		return fmt.Errorf("failed to delete tracked entity for user %s: %w", userId, err)
	}
	return nil
}
