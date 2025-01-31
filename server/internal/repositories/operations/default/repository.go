package defaultRepository

import (
	"fmt"
	"strings"
	"verni/internal/db"
	"verni/internal/repositories"
	"verni/internal/repositories/operations"
	"verni/internal/services/logging"
)

func New(db db.DB, logger logging.Service) operations.Repository {
	return &defaultRepository{
		db:     db,
		logger: logger,
	}
}

type defaultRepository struct {
	db     db.DB
	logger logging.Service
}

func (c *defaultRepository) Push(
	operations []operations.Operation,
	userId operations.UserId,
	deviceId operations.DeviceId,
) repositories.Transaction {

}

func (c *defaultRepository) Pull(
	userId operations.UserId,
	deviceId operations.DeviceId,
	ignoreLargeoperations bool,
) ([]operations.Operation, error) {
	const op = "repositories.operations.defaultRepository.Pull"
	c.logger.LogInfo("%s: start[user=%s device=%s]", op, userId, deviceId)
}

func (c *defaultRepository) Confirm(
	operationIds []operations.OperationId,
	user operations.UserId,
	device operations.DeviceId,
) repositories.Transaction {
	const op = "repositories.operations.defaultRepository.Confirm"

	toFilter, err := c.getConfirmed(operationIds, user, device)
	if err != nil {
		err = fmt.Errorf("%s: failed to get confirmed operations: %w", op, err)
		c.logger.LogInfo("%v", err)
		return repositories.Transaction{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	filterMap := make(map[operations.OperationId]struct{}, len(toFilter))
	for _, operation := range toFilter {
		filterMap[operation] = struct{}{}
	}

	var toConfirm []operations.OperationId
	for _, operation := range operationIds {
		if _, found := filterMap[operation]; !found {
			toConfirm = append(toConfirm, operation)
		}
	}

	if len(toConfirm) == 0 {
		c.logger.LogInfo("%s: nothing to confirm, early return", op)
		return repositories.Transaction{
			Perform:  func() error { return nil },
			Rollback: func() error { return nil },
		}
	}

	return repositories.Transaction{
		Perform: func() error {
			return c.markConfirmed(toConfirm, true, user, device)
		},
		Rollback: func() error {
			return c.markConfirmed(toConfirm, false, user, device)
		},
	}
}

func (c *defaultRepository) markConfirmed(
	operationIds []operations.OperationId,
	confirmed bool,
	userId operations.UserId,
	deviceId operations.DeviceId,
) error {
	const op = "repositories.operations.defaultRepository.markConfirmed"
	c.logger.LogInfo("%s: start[user=%s device=%s confirmed=%t]", op, userId, deviceId, confirmed)

	if len(operationIds) == 0 {
		return nil
	}

	var query string
	if confirmed {
		valuePlaceholders := make([]string, len(operationIds))
		for i := range operationIds {
			valuePlaceholders[i] = fmt.Sprintf("($1, $2, $%d)", i+3)
		}
		query = fmt.Sprintf(`
INSERT INTO confirmedOperations (userId, deviceId, operationId)
VALUES %s
ON CONFLICT (userId, deviceId, operationId) DO NOTHING;`, strings.Join(valuePlaceholders, ", "))
	} else {
		placeholders := make([]string, len(operationIds))
		for i := range operationIds {
			placeholders[i] = fmt.Sprintf("$%d", i+3)
		}
		query = fmt.Sprintf(`
DELETE FROM confirmedOperations
WHERE userId = $1 AND deviceId = $2 AND operationId IN (%s);`, strings.Join(placeholders, ", "))
	}

	args := make([]interface{}, 0, len(operationIds)+2)
	args = append(args, string(userId), string(deviceId))
	for _, id := range operationIds {
		args = append(args, id)
	}

	if _, err := c.db.Exec(query, args...); err != nil {
		return fmt.Errorf("%s: failed to execute query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s device=%s confirmed=%t]", op, userId, deviceId, confirmed)
	return nil
}

func (c *defaultRepository) getConfirmed(
	operationIds []operations.OperationId,
	userId operations.UserId,
	deviceId operations.DeviceId,
) ([]operations.OperationId, error) {
	const op = "repositories.operations.defaultRepository.getConfirmed"
	c.logger.LogInfo("%s: start[user=%s device=%s]", op, userId, deviceId)

	if len(operationIds) == 0 {
		return nil, nil
	}

	placeholders := make([]string, len(operationIds))
	for i := range operationIds {
		placeholders[i] = fmt.Sprintf("$%d", i+1)
	}

	query := fmt.Sprintf(`
SELECT operationId FROM confirmedOperations
WHERE userId = $%d AND deviceId = $%d AND operationId IN (%s);`,
		len(operationIds)+1, len(operationIds)+2, strings.Join(placeholders, ", "))

	// Prepare arguments for the query
	args := make([]interface{}, len(operationIds)+2)
	for i, id := range operationIds {
		args[i] = id
	}
	args[len(operationIds)] = string(userId)
	args[len(operationIds)+1] = string(deviceId)

	rows, err := c.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("%s: failed to execute query: %w", op, err)
	}
	defer rows.Close()

	var results []operations.OperationId
	for rows.Next() {
		var operationId string
		if err := rows.Scan(&operationId); err != nil {
			return nil, fmt.Errorf("%s: failed to scan row: %w", op, err)
		}
		results = append(results, operations.OperationId(operationId))
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("%s: error occurred during row iteration: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s device=%s]", op, userId, deviceId)
	return results, nil
}

func (c *defaultRepository) getTrackedEntities(user operations.UserId) ([]operations.TrackedEntity, error) {
	const op = "repositories.operations.defaultRepository.getTrackedEntities"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `SELECT entityId, entityType FROM trackedEntities WHERE userId = $1;`

	rows, err := c.db.Query(query, string(user))
	if err != nil {
		return nil, fmt.Errorf("%s: failed to execute query: %w", op, err)
	}
	defer rows.Close()

	var entities []operations.TrackedEntity
	for rows.Next() {
		var entity operations.TrackedEntity
		if err := rows.Scan(&entity.Id, &entity.Type); err != nil {
			return nil, fmt.Errorf("%s: failed to scan row: %w", op, err)
		}
		entities = append(entities, entity)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("%s: error occurred during row iteration: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return entities, nil
}

func (c *defaultRepository) Get(affectingEntities []operations.TrackedEntity) ([]operations.Operation, error) {

}

func (c *defaultRepository) Search(payloadType string, hint string) ([]operations.Operation, error) {

}
