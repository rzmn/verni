package defaultRepository

import (
	"database/sql"
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
	confirm bool,
) repositories.Transaction {
	return repositories.Transaction{
		Perform: func() error {
			return c.push(operations, userId, deviceId, confirm)
		},
		Rollback: func() error {
			return c.pushRollback(operations, userId, deviceId, confirm)
		},
	}
}

func (c *defaultRepository) Pull(
	userId operations.UserId,
	deviceId operations.DeviceId,
	ignoreLargeoperations bool,
) ([]operations.Operation, error) {
	const op = "repositories.operations.defaultRepository.Pull"
	c.logger.LogInfo("%s: start[user=%s device=%s]", op, userId, deviceId)

	query := `
SELECT
    o.operationId,
    o.createdAt,
    o.data,
    o.isLarge,
    o.searchHint,
    ae.entityId,
    ae.entityType
FROM operations o
JOIN operationsAffectingEntity ae ON o.operationId = ae.operationId
WHERE ae.operationId IN (
    SELECT oe.operationId
    FROM operationsAffectingEntity oe
    WHERE oe.operationId NOT IN (
        SELECT co.operationId
        FROM confirmedOperations co
        WHERE co.userId = $1 AND co.deviceId = $2
    )
) AND (ae.entityId, ae.entityType) IN (
    SELECT te.entityId, te.entityType
    FROM trackedEntities te
    WHERE te.userId = $1
);`

	rows, err := c.db.Query(query, userId, deviceId)
	if err != nil {
		return nil, fmt.Errorf("%s: failed to execute query: %w", op, err)
	}
	defer rows.Close()

	payloadMap := make(map[operations.OperationId]rawPayload)
	operationsMap := make(map[operations.OperationId]operations.Operation)

	for rows.Next() {
		var operation operations.Operation
		var payload rawPayload

		var entityID string
		var entityType string
		var searchHint sql.NullString

		if err := rows.Scan(
			&operation.OperationId,
			&operation.CreatedAt,
			&payload.data,
			&payload.isLarge,
			&searchHint,
			&entityID,
			&entityType,
		); err != nil {
			return nil, fmt.Errorf("%s: failed to scan row: %w", op, err)
		}

		if searchHint.Valid {
			payload.searchHint = &searchHint.String
		}

		payload.trackedEntities = append(payload.trackedEntities, operations.TrackedEntity{
			Id:   entityID,
			Type: entityType,
		})

		if existingPayload, exists := payloadMap[operation.OperationId]; exists {
			payload = existingPayload
		}

		operation.Payload = &payload
		operationsMap[operation.OperationId] = operation
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("%s: error occurred during row iteration: %w", op, err)
	}

	result := make([]operations.Operation, 0, len(operationsMap))
	for _, operation := range operationsMap {
		result = append(result, operation)
	}

	c.logger.LogInfo("%s: success[user=%s device=%s]", op, userId, deviceId)

	return result, nil
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
	const op = "repositories.operations.defaultRepository.Get"
	c.logger.LogInfo("%s: start", op)

	if len(affectingEntities) == 0 {
		c.logger.LogInfo("%s: no entities provided, early return", op)
		return nil, nil
	}

	query := `
SELECT
    o.operationId,
    o.createdAt,
    o.data,
    o.isLarge,
    o.searchHint,
    ae.entityId,
    ae.entityType
FROM operations o
JOIN operationsAffectingEntity ae ON o.operationId = ae.operationId
WHERE `

	var conditions []string
	var args []interface{}
	for i, entity := range affectingEntities {
		conditions = append(conditions, fmt.Sprintf("(ae.entityId = $%d AND ae.entityType = $%d)", i*2+1, i*2+2))
		args = append(args, entity.Id, entity.Type)
	}

	query += strings.Join(conditions, " OR ")

	rows, err := c.db.Query(query, args...)
	if err != nil {
		return nil, fmt.Errorf("%s: failed to execute query: %w", op, err)
	}
	defer rows.Close()

	operationsMap := make(map[operations.OperationId]operations.Operation)

	for rows.Next() {
		var operation operations.Operation
		var payload rawPayload
		var entityID, entityType string
		var searchHint sql.NullString

		if err := rows.Scan(&operation.OperationId, &operation.CreatedAt, &payload.data, &payload.isLarge, &searchHint, &entityID, &entityType); err != nil {
			return nil, fmt.Errorf("%s: failed to scan row: %w", op, err)
		}

		if searchHint.Valid {
			payload.searchHint = &searchHint.String
		}

		trackedEntity := operations.TrackedEntity{
			Id:   entityID,
			Type: entityType,
		}

		if existingOp, exists := operationsMap[operation.OperationId]; exists {
			operation = existingOp
		}

		payload.trackedEntities = append(payload.trackedEntities, trackedEntity)
		operation.Payload = &payload

		operationsMap[operation.OperationId] = operation
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("%s: error occurred during row iteration: %w", op, err)
	}

	result := make([]operations.Operation, 0, len(operationsMap))
	for _, operation := range operationsMap {
		result = append(result, operation)
	}
	c.logger.LogInfo("%s: success", op)

	return result, nil
}

func (c *defaultRepository) Search(payloadType string, hint string) ([]operations.Operation, error) {
	const op = "repositories.operations.defaultRepository.Search"
	c.logger.LogInfo("%s: start[type=%s hint=%s]", op, payloadType, hint)

	query := `
SELECT
    o.operationId,
    o.createdAt,
    o.data,
    o.isLarge,
    o.searchHint,
    ae.entityId,
    ae.entityType
FROM operations o
JOIN operationsAffectingEntity ae ON o.operationId = ae.operationId
WHERE o.operationType = $1
  AND o.searchHint IS NOT NULL
  AND o.searchHint LIKE '%' || $2 || '%';`

	rows, err := c.db.Query(query, payloadType, hint)
	if err != nil {
		return nil, fmt.Errorf("%s: failed to execute query: %w", op, err)
	}
	defer rows.Close()

	operationsMap := make(map[operations.OperationId]operations.Operation)
	payloadMap := make(map[operations.OperationId]rawPayload)

	for rows.Next() {
		var operation operations.Operation
		var payload rawPayload
		var entityID string
		var entityType string
		var searchHint sql.NullString

		if err := rows.Scan(&operation.OperationId, &operation.CreatedAt, &payload.data, &payload.isLarge, &searchHint, &entityID, &entityType); err != nil {
			return nil, fmt.Errorf("%s: failed to scan row: %w", op, err)
		}

		if searchHint.Valid {
			payload.searchHint = &searchHint.String
		}

		trackedEntity := operations.TrackedEntity{
			Id:   entityID,
			Type: entityType,
		}

		if current, exists := payloadMap[operation.OperationId]; exists {
			payload = current
		}

		payload.trackedEntities = append(payload.trackedEntities, trackedEntity)
		operation.Payload = &payload

		operationsMap[operation.OperationId] = operation
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("%s: error occurred during row iteration: %w", op, err)
	}

	result := make([]operations.Operation, 0, len(operationsMap))
	for _, operation := range operationsMap {
		result = append(result, operation)
	}

	c.logger.LogInfo("%s: success[type=%s hint=%s]", op, payloadType, hint)

	return result, nil
}
