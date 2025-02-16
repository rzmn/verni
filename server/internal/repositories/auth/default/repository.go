package defaultRepository

import (
	"database/sql"
	"fmt"
	"strings"

	"verni/internal/db"
	"verni/internal/repositories"
	"verni/internal/repositories/auth"
	"verni/internal/services/logging"
)

func New(db db.DB, logger logging.Service) auth.Repository {
	return &defaultRepository{
		db:     db,
		logger: logger,
	}
}

type defaultRepository struct {
	db     db.DB
	logger logging.Service
}

func (c *defaultRepository) CreateUser(user auth.UserId, email string, password string) repositories.UnitOfWork {
	return repositories.UnitOfWork{
		Perform: func() error {
			return c.createUser(user, email, password)
		},
		Rollback: func() error {
			return c.deleteUser(user)
		},
	}
}

func (c *defaultRepository) createUser(user auth.UserId, email, password string) error {
	const op = "repositories.auth.defaultRepository.createUser"
	c.logger.LogInfo("%s: start[user=%s email=%s]", op, user, email)

	passwordHash, err := hashPassword(password)
	if err != nil {
		return fmt.Errorf("%s: cannot hash password: %w", op, err)
	}
	userWithEmail, err := c.GetUserIdByEmail(email)
	if err != nil {
		return fmt.Errorf("%s: getting user id by email: %w", op, err)
	}
	if userWithEmail != nil {
		return fmt.Errorf("%s: user with email %s already exists", op, email)
	}

	query := `INSERT INTO credentials(userId, email, password, emailVerified) VALUES($1, $2, $3, False);`
	if _, err := c.db.Exec(query, string(user), email, passwordHash); err != nil {
		return fmt.Errorf("%s: failed to execute query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[uid=%s email=%s]", op, user, email)
	return nil
}

func (c *defaultRepository) deleteUser(user auth.UserId) error {
	const op = "repositories.auth.defaultRepository.deleteUser"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `DELETE FROM credentials WHERE userId = $1;`
	if _, err := c.db.Exec(query, string(user)); err != nil {
		return fmt.Errorf("%s: failed to execute query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[uid=%s]", op, user)
	return nil
}

func (c *defaultRepository) MarkUserEmailValidated(user auth.UserId) repositories.UnitOfWork {
	const op = "repositories.auth.defaultRepository.MarkUserEmailValidated"

	existed, err := c.GetUserInfo(user)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current credentials: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.UnitOfWork{
		Perform: func() error {
			if existed.EmailVerified {
				return nil
			}
			return c.updateEmail(user, existed.Email, true)
		},
		Rollback: func() error {
			if existed.EmailVerified {
				return nil
			}
			return c.updateEmail(user, existed.Email, false)
		},
	}
}

func (c *defaultRepository) IsUserExists(user auth.UserId) (bool, error) {
	const op = "repositories.auth.defaultRepository.IsUserExists"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `SELECT EXISTS(SELECT 1 FROM credentials WHERE userId = $1);`
	var exists bool
	if err := c.db.QueryRow(query, string(user)).Scan(&exists); err != nil {
		return false, fmt.Errorf("%s: failed to scan result: %w", op, err)
	}

	c.logger.LogInfo("%s: success[uid=%s]", op, user)
	return exists, nil
}

func (c *defaultRepository) IsSessionExists(user auth.UserId, device auth.DeviceId) (bool, error) {
	const op = "repositories.auth.defaultRepository.IsSessionExists"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `SELECT EXISTS(SELECT 1 FROM refreshTokens WHERE userId = $1 AND deviceId = $2);`
	var exists bool
	if err := c.db.QueryRow(query, string(user), string(device)).Scan(&exists); err != nil {
		return false, fmt.Errorf("%s: failed to scan result: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return exists, nil
}

func (c *defaultRepository) ExclusiveSession(user auth.UserId, device auth.DeviceId) repositories.UnitOfWork {
	const op = "repositories.auth.defaultRepository.ExclusiveSession"

	tokensData, err := c.getTokenDataPerDevice(user)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current token data: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}
	delete(tokensData, device)

	return repositories.UnitOfWork{
		Perform: func() error {
			devices := []auth.DeviceId{}
			for device := range tokensData {
				devices = append(devices, device)
			}
			return c.removeTokenData(user, devices)
		},
		Rollback: func() error {
			var result error = nil
			for device, token := range tokensData {
				if err := c.updateRefreshToken(user, device, token); err != nil {
					c.logger.LogInfo("%s: encountered error rolling back token data: %v", op, err)
					result = err
				}
			}
			return result
		},
	}
}

func (c *defaultRepository) getTokenDataPerDevice(user auth.UserId) (map[auth.DeviceId]string, error) {
	const op = "repositories.auth.defaultRepository.getTokenDataPerDevice"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	tokensMap := map[auth.DeviceId]string{}
	query := `SELECT deviceId, refreshToken FROM refreshTokens WHERE userId = $1`

	rows, err := c.db.Query(query, user)
	if err != nil {
		return nil, fmt.Errorf("failed to execute query: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var deviceId, refreshToken string
		if err := rows.Scan(&deviceId, &refreshToken); err != nil {
			return nil, fmt.Errorf("failed to scan row: %w", err)
		}
		tokensMap[auth.DeviceId(deviceId)] = refreshToken
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error encountered during iteration: %w", err)
	}

	return tokensMap, nil
}

func (c *defaultRepository) removeTokenData(user auth.UserId, devices []auth.DeviceId) error {
	const op = "repositories.auth.defaultRepository.removeTokenData"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	if len(devices) == 0 {
		c.logger.LogInfo("%s: no devices passed, early empty return", op, user)
		return nil
	}

	placeholders := make([]string, len(devices))
	for i := range devices {
		placeholders[i] = fmt.Sprintf("$%d", i+2)
	}

	query := fmt.Sprintf("DELETE FROM refreshTokens WHERE userId = $1 AND deviceId IN (%s)", strings.Join(placeholders, ", "))
	args := []interface{}{string(user)}
	for _, device := range devices {
		args = append(args, string(device))
	}

	if _, err := c.db.Exec(query, args...); err != nil {
		return fmt.Errorf("failed to execute delete query: %w", err)
	}

	return nil
}

func (c *defaultRepository) CheckCredentials(email, password string) (bool, error) {
	const op = "repositories.auth.defaultRepository.CheckCredentials"
	c.logger.LogInfo("%s: start[email=%s]", op, email)

	var passwordHash string
	query := `SELECT password FROM credentials WHERE email = $1;`
	err := c.db.QueryRow(query, email).Scan(&passwordHash)

	if err != nil {
		if err == sql.ErrNoRows {
			c.logger.LogInfo("%s: no user associated with email", op)
			return false, nil
		}
		return false, fmt.Errorf("%s: failed to scan password: %w", op, err)
	}

	return checkPasswordHash(password, passwordHash), nil
}

func (c *defaultRepository) GetUserIdByEmail(email string) (*auth.UserId, error) {
	const op = "repositories.auth.defaultRepository.GetUserIdByEmail"
	c.logger.LogInfo("%s: start[email=%s]", op, email)

	query := `SELECT userId FROM credentials WHERE email = $1;`
	var id string

	err := c.db.QueryRow(query, email).Scan(&id)
	if err != nil {
		if err == sql.ErrNoRows {
			c.logger.LogInfo("%s: no user found for email=%s", op, email)
			return nil, nil
		}
		return nil, fmt.Errorf("%s: failed to scan row: %w", op, err)
	}

	c.logger.LogInfo("%s: success[email=%s]", op, email)
	return (*auth.UserId)(&id), nil
}

func (c *defaultRepository) UpdateRefreshToken(user auth.UserId, device auth.DeviceId, token string) repositories.UnitOfWork {
	const op = "repositories.auth.defaultRepository.UpdateRefreshToken"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)

	existed, err := c.getTokenDataPerDevice(user)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current credentials: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.UnitOfWork{
		Perform: func() error {
			return c.updateRefreshToken(user, device, token)
		},
		Rollback: func() error {
			if previousToken, ok := existed[device]; ok {
				return c.updateRefreshToken(user, device, previousToken)
			}
			return c.removeTokenData(user, []auth.DeviceId{device})
		},
	}
}

func (c *defaultRepository) updateRefreshToken(user auth.UserId, device auth.DeviceId, token string) error {
	const op = "repositories.auth.defaultRepository.updateRefreshToken"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `
INSERT INTO refreshTokens(userId, deviceId, refreshToken)
VALUES ($1, $2, $3)
ON CONFLICT (userId, deviceId) DO UPDATE SET refreshToken = EXCLUDED.refreshToken;
`

	_, err := c.db.Exec(query, string(user), string(device), token)
	if err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return nil
}

func (c *defaultRepository) CheckRefreshToken(user auth.UserId, device auth.DeviceId, token string) (bool, error) {
	const op = "repositories.auth.defaultRepository.CheckRefreshToken"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `SELECT EXISTS(SELECT 1 FROM refreshTokens WHERE userId = $1 AND deviceId = $2 AND refreshToken = $3);`
	var exists bool

	if err := c.db.QueryRow(query, string(user), string(device), token).Scan(&exists); err != nil {
		return false, fmt.Errorf("%s: failed to perform scan: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return exists, nil
}

func (c *defaultRepository) UpdatePassword(user auth.UserId, password string) repositories.UnitOfWork {
	const op = "repositories.auth.defaultRepository.UpdatePassword"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	existed, err := c.GetUserInfo(user)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current credentials: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	passwordHash, err := hashPassword(password)
	if err != nil {
		c.logger.LogInfo("%s: cannot hash password: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.UnitOfWork{
		Perform: func() error {
			return c.updatePassword(user, passwordHash)
		},
		Rollback: func() error {
			return c.updatePassword(user, existed.PasswordHash)
		},
	}
}

func (c *defaultRepository) updatePassword(user auth.UserId, passwordHash string) error {
	const op = "repositories.auth.defaultRepository.updatePassword"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `UPDATE credentials SET password = $2 WHERE userId = $1;`
	if _, err := c.db.Exec(query, string(user), passwordHash); err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return nil
}

func (c *defaultRepository) UpdateEmail(user auth.UserId, newEmail string) repositories.UnitOfWork {
	const op = "repositories.auth.defaultRepository.UpdateEmail"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	existed, err := c.GetUserInfo(user)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current credentials: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.UnitOfWork{
		Perform: func() error {
			return c.updateEmail(user, newEmail, false)
		},
		Rollback: func() error {
			return c.updateEmail(user, existed.Email, existed.EmailVerified)
		},
	}
}

func (c *defaultRepository) updateEmail(user auth.UserId, newEmail string, verified bool) error {
	const op = "repositories.auth.defaultRepository.updateEmail"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	userWithEmail, err := c.GetUserIdByEmail(newEmail)
	if err != nil {
		return fmt.Errorf("%s: getting user id by email: %w", op, err)
	}
	if userWithEmail != nil && *userWithEmail != user {
		return fmt.Errorf("%s: user with email %s already exists", op, newEmail)
	}

	query := `UPDATE credentials SET email = $2, emailVerified = $3 WHERE userId = $1;`
	if _, err := c.db.Exec(query, string(user), newEmail, verified); err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return nil
}

func (c *defaultRepository) GetUserInfo(user auth.UserId) (auth.UserInfo, error) {
	const op = "repositories.auth.defaultRepository.GetUserInfo"
	c.logger.LogInfo("%s: start[user=%s]", op, user)

	query := `SELECT email, password, emailVerified FROM credentials WHERE userId = $1;`
	row := c.db.QueryRow(query, string(user))

	var result auth.UserInfo
	result.UserId = user

	if err := row.Scan(&result.Email, &result.PasswordHash, &result.EmailVerified); err != nil {
		return auth.UserInfo{}, fmt.Errorf("%s: failed to scan row: %w", op, err)
	}

	c.logger.LogInfo("%s: success[user=%s]", op, user)
	return result, nil
}
