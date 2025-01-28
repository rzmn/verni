package defaultRepository

import (
	"fmt"
	"verni/internal/db"
	"verni/internal/repositories"
	"verni/internal/repositories/pushNotifications"
	"verni/internal/services/logging"
)

func New(db db.DB, logger logging.Service) pushNotifications.Repository {
	return &defaultRepository{
		db:     db,
		logger: logger,
	}
}

type defaultRepository struct {
	db     db.DB
	logger logging.Service
}

func (c *defaultRepository) StorePushToken(user pushNotifications.UserId, device pushNotifications.DeviceId, token string) repositories.Transaction {
	const op = "repositories.pushNotifications.postgresRepository.StorePushToken"
	currentToken, err := c.GetPushToken(user, device)
	return repositories.Transaction{
		Perform: func() error {
			if err != nil {
				err := fmt.Errorf("getting token info: %w", err)
				c.logger.LogInfo("%s: %v", op, err)
				return err
			}
			return c.storePushToken(user, device, token)
		},
		Rollback: func() error {
			if err != nil {
				err := fmt.Errorf("getting token info for rollback: %w", err)
				c.logger.LogInfo("%s: %v", op, err)
				return err
			}
			if currentToken == nil {
				return c.removePushToken(user, device)
			} else {
				return c.storePushToken(user, device, *currentToken)
			}
		},
	}
}

func (c *defaultRepository) storePushToken(user pushNotifications.UserId, device pushNotifications.DeviceId, token string) error {
	const op = "repositories.pushNotifications.postgresRepository.storePushToken"
	c.logger.LogInfo("%s: start[uid=%v]", op, user)
	query := `
INSERT INTO pushTokens(userId, deviceId, token) VALUES ($1, $2, $3)
ON CONFLICT (id) DO UPDATE SET token = $3;
`
	_, err := c.db.Exec(query, string(user), string(device), token)
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%v]", op, user)
	return nil
}

func (c *defaultRepository) removePushToken(user pushNotifications.UserId, device pushNotifications.DeviceId) error {
	const op = "repositories.pushNotifications.postgresRepository.removePushToken"
	c.logger.LogInfo("%s: start[uid=%v]", op, user)
	query := `DELETE FROM pushTokens WHERE userId = $1 AND deviceId = $2;`
	_, err := c.db.Exec(query, string(user), string(device))
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%v]", op, user)
	return nil
}

func (c *defaultRepository) GetPushToken(user pushNotifications.UserId, device pushNotifications.DeviceId) (*string, error) {
	const op = "repositories.pushNotifications.postgresRepository.GetPushToken"
	c.logger.LogInfo("%s: start[uid=%v]", op, user)
	query := `SELECT token FROM pushTokens WHERE userId = $1 AND deviceId = $2;`
	rows, err := c.db.Query(query, string(user), string(device))
	if err != nil {
		err := fmt.Errorf("getting push token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return nil, err
	}
	defer rows.Close()
	if rows.Next() {
		var token string
		if err := rows.Scan(&token); err != nil {
			err := fmt.Errorf("scanning row for push token: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return nil, err
		}
		if err := rows.Err(); err != nil {
			err := fmt.Errorf("checking rows for push token: %w", err)
			c.logger.LogInfo("%s: %v", op, err)
			return nil, err
		}
		c.logger.LogInfo("%s: success[uid=%v]", op, user)
		return &token, nil
	}
	c.logger.LogInfo("%s: success[uid=%v]", op, user)
	return nil, nil
}
