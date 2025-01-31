package defaultRepository

import (
	"database/sql"
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
	const op = "repositories.pushNotifications.defaultRepository.StorePushToken"

	currentToken, err := c.GetPushToken(user, device)
	if err != nil {
		err = fmt.Errorf("%s: getting token info: %w", op, err)
		c.logger.LogInfo("%v", err)
		return repositories.Transaction{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.Transaction{
		Perform: func() error {
			return c.storePushToken(user, device, token)
		},
		Rollback: func() error {
			if currentToken == nil {
				return c.removePushToken(user, device)
			}
			return c.storePushToken(user, device, *currentToken)
		},
	}
}

func (c *defaultRepository) storePushToken(user pushNotifications.UserId, device pushNotifications.DeviceId, token string) error {
	const op = "repositories.pushNotifications.defaultRepository.storePushToken"
	c.logger.LogInfo("%s: start[user=%v]", op, user)

	query := `
INSERT INTO pushTokens(userId, deviceId, token)
VALUES ($1, $2, $3)
ON CONFLICT (userId, deviceId) DO UPDATE SET token = EXCLUDED.token;
`

	if _, err := c.db.Exec(query, string(user), string(device), token); err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%v]", op, user)
	return nil
}

func (c *defaultRepository) removePushToken(user pushNotifications.UserId, device pushNotifications.DeviceId) error {
	const op = "repositories.pushNotifications.defaultRepository.removePushToken"
	c.logger.LogInfo("%s: start[user=%v]", op, user)

	query := `DELETE FROM pushTokens WHERE userId = $1 AND deviceId = $2;`
	if _, err := c.db.Exec(query, string(user), string(device)); err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%v]", op, user)
	return nil
}

func (c *defaultRepository) GetPushToken(user pushNotifications.UserId, device pushNotifications.DeviceId) (*string, error) {
	const op = "repositories.pushNotifications.postgresRepository.GetPushToken"
	c.logger.LogInfo("%s: start[user=%v]", op, user)

	query := `SELECT token FROM pushTokens WHERE userId = $1 AND deviceId = $2;`
	row := c.db.QueryRow(query, string(user), string(device))

	var token string
	if err := row.Scan(&token); err != nil {
		if err == sql.ErrNoRows {
			c.logger.LogInfo("%s: no token found for uid=%v", op, user)
			return nil, nil
		}
		return nil, fmt.Errorf("%s: scanning row for push token: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%v]", op, user)
	return &token, nil
}
