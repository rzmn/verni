package defaultRepository

import (
	"database/sql"

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

func (c *defaultRepository) CreateUser(user auth.UserId, email string, password string) repositories.Transaction {
	return repositories.Transaction{
		Perform: func() error {
			return c.createUser(user, email, password)
		},
		Rollback: func() error {
			return c.deleteUser(user)
		},
	}
}

func (c *defaultRepository) createUser(user auth.UserId, email string, password string) error {
	const op = "repositories.auth.postgresRepository.createUser"
	c.logger.LogInfo("%s: start[uid=%s email=%s]", op, user, email)
	passwordHash, err := hashPassword(password)
	if err != nil {
		c.logger.LogInfo("%s: cannot hash password %v", op, err)
		return err
	}
	query := `INSERT INTO credentials(userId, email, password, emailVerified) VALUES($1, $2, $3, False);`
	_, err = c.db.Exec(query, string(user), string(email), passwordHash)
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%s email=%s]", op, user, email)
	return nil
}

func (c *defaultRepository) deleteUser(uid auth.UserId) error {
	const op = "repositories.auth.postgresRepository.deleteUser"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	query := `DELETE FROM credentials WHERE id = $1;`
	_, err := c.db.Exec(query, string(uid))
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, uid)
	return nil
}

func (c *defaultRepository) MarkUserEmailValidated(user auth.UserId) repositories.Transaction {
	const op = "repositories.auth.postgresRepository.MarkUserEmailValidated"
	existed, err := c.GetUserInfo(user)
	return repositories.Transaction{
		Perform: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			if existed.EmailVerified {
				return nil
			} else {
				return c.updateEmail(user, existed.Email, true)
			}
		},
		Rollback: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			if existed.EmailVerified {
				return nil
			} else {
				return c.updateEmail(user, existed.Email, false)
			}
		},
	}
}

func (c *defaultRepository) IsUserExists(user auth.UserId) (bool, error) {
	const op = "repositories.auth.postgresRepository.IsUserExists"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)
	query := `SELECT EXISTS(SELECT 1 FROM credentials WHERE id = $1);`
	row := c.db.QueryRow(query, string(user))
	var exists bool
	if err := row.Scan(&exists); err != nil {
		c.logger.LogInfo("%s: failed to perform scan err: %v", op, err)
		return false, err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, user)
	return exists, nil
}

func (c *defaultRepository) IsSessionExists(user auth.UserId, device auth.DeviceId) (bool, error) {
	const op = "repositories.auth.postgresRepository.IsSessionExists"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)
	query := `SELECT EXISTS(SELECT 1 FROM refreshTokens WHERE userId = $1 AND deviceId = $2);`
	row := c.db.QueryRow(query, string(user), string(device))
	var exists bool
	if err := row.Scan(&exists); err != nil {
		c.logger.LogInfo("%s: failed to perform scan err: %v", op, err)
		return false, err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, user)
	return exists, nil
}

func (c *defaultRepository) ExclusiveSession(user auth.UserId, device auth.DeviceId) repositories.Transaction {
	const op = "repositories.auth.postgresRepository.ExclusiveSession"
	tokensData, err := c.getTokenDataPerDevice(user)
	return repositories.Transaction{
		Perform: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			delete(tokensData, device)
			devices := []auth.DeviceId{}
			for device := range tokensData {
				devices = append(devices, device)
			}
			return c.removeTokenData(user, devices)
		},
		Rollback: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			delete(tokensData, device)
			var result error = nil
			for device, token := range tokensData {
				if err := c.updateRefreshToken(user, device, token); err != nil {
					result = err
				}
			}
			return result
		},
	}
}

func (c *defaultRepository) getTokenDataPerDevice(user auth.UserId) (map[auth.DeviceId]string, error) {

}

func (c *defaultRepository) removeTokenData(user auth.UserId, devices []auth.DeviceId) error {

}

func (c *defaultRepository) CheckCredentials(email string, password string) (bool, error) {
	const op = "repositories.auth.postgresRepository.CheckCredentials"
	c.logger.LogInfo("%s: start[email=%s]", op, email)
	query := `SELECT password FROM credentials WHERE email = $1;`
	row := c.db.QueryRow(query, email)
	var passwordHash string
	if err := row.Scan(&passwordHash); err != nil {
		if err == sql.ErrNoRows {
			c.logger.LogInfo("%s: no user associated with email err: %v", op, err)
			return false, nil
		} else {
			c.logger.LogInfo("%s: failed to perform scan err: %v", op, err)
			return false, err
		}
	}
	c.logger.LogInfo("%s: start[email=%s]", op, email)
	return checkPasswordHash(password, passwordHash), nil
}

func (c *defaultRepository) GetUserIdByEmail(email string) (*auth.UserId, error) {
	const op = "repositories.auth.postgresRepository.GetUserIdByEmail"
	c.logger.LogInfo("%s: start[email=%s]", op, email)
	query := `SELECT userId FROM credentials WHERE email = $1;`
	rows, err := c.db.Query(query, email)
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return nil, err
	}
	defer rows.Close()
	if rows.Next() {
		var id string
		if err := rows.Scan(&id); err != nil {
			c.logger.LogInfo("%s: failed to perform scan err: %v", op, err)
			return nil, err
		}
		if err := rows.Err(); err != nil {
			c.logger.LogInfo("%s: found rows err: %v", op, err)
			return nil, err
		}
		c.logger.LogInfo("%s: success[email=%s]", op, email)
		return (*auth.UserId)(&id), nil
	}
	if err := rows.Err(); err != nil {
		c.logger.LogInfo("%s: found rows err: %v", op, err)
		return nil, err
	}
	c.logger.LogInfo("%s: success[email=%s]", op, email)
	return nil, nil
}

func (c *defaultRepository) UpdateRefreshToken(user auth.UserId, device auth.DeviceId, token string) repositories.Transaction {
	const op = "repositories.auth.postgresRepository.UpdateRefreshToken"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)
	existed, err := c.getTokenDataPerDevice(user)
	return repositories.Transaction{
		Perform: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			return c.updateRefreshToken(user, device, token)
		},
		Rollback: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			previousToken, ok := existed[device]
			if ok {
				return c.updateRefreshToken(user, device, previousToken)
			} else {
				return c.removeTokenData(user, []auth.DeviceId{device})
			}
		},
	}
}

func (c *defaultRepository) updateRefreshToken(user auth.UserId, device auth.DeviceId, token string) error {
	const op = "repositories.auth.postgresRepository.updateRefreshToken"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)
	query := `
INSERT INTO refreshTokens(userId, deviceId, refreshToken) VALUES ($1, $2, $3)
ON CONFLICT (userId, deviceId) DO UPDATE SET refreshToken = $3;
`
	_, err := c.db.Exec(query, string(user), string(device), token)
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, user)
	return nil
}

func (c *defaultRepository) CheckRefreshToken(user auth.UserId, device auth.DeviceId, token string) (bool, error) {
	const op = "repositories.auth.postgresRepository.CheckRefreshToken"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)
	query := `SELECT EXISTS(SELECT 1 FROM refreshTokens WHERE userId = $1 AND deviceId = $2 AND refreshToken = $3);`
	row := c.db.QueryRow(query, string(user), string(device), token)
	var exists bool
	if err := row.Scan(&exists); err != nil {
		c.logger.LogInfo("%s: failed to perform scan err: %v", op, err)
		return false, err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, user)
	return exists, nil
}

func (c *defaultRepository) UpdatePassword(user auth.UserId, password string) repositories.Transaction {
	const op = "repositories.auth.postgresRepository.UpdatePassword"
	c.logger.LogInfo("%s: start[uid=%s]", op, user)
	existed, getCredentialsErr := c.GetUserInfo(user)
	passwordHash, hashPasswordErr := hashPassword(password)
	return repositories.Transaction{
		Perform: func() error {
			if getCredentialsErr != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, getCredentialsErr)
				return getCredentialsErr
			}
			if hashPasswordErr != nil {
				c.logger.LogInfo("%s: cannot hash password %v", op, hashPasswordErr)
				return hashPasswordErr
			}
			return c.updatePassword(user, passwordHash)
		},
		Rollback: func() error {
			if getCredentialsErr != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, getCredentialsErr)
				return getCredentialsErr
			}
			return c.updatePassword(user, existed.PasswordHash)
		},
	}
}

func (c *defaultRepository) updatePassword(uid auth.UserId, passwordHash string) error {
	const op = "repositories.auth.postgresRepository.updatePassword"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	query := `UPDATE credentials SET password = $2 WHERE id = $1;`
	_, err := c.db.Exec(query, string(uid), passwordHash)
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, uid)
	return nil
}

func (c *defaultRepository) UpdateEmail(uid auth.UserId, newEmail string) repositories.Transaction {
	const op = "repositories.auth.postgresRepository.UpdateEmail"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	existed, err := c.GetUserInfo(uid)
	return repositories.Transaction{
		Perform: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			return c.updateEmail(uid, newEmail, false)
		},
		Rollback: func() error {
			if err != nil {
				c.logger.LogInfo("%s: failed to get current credentals err: %v", op, err)
				return err
			}
			if err := c.updateEmail(uid, existed.Email, existed.EmailVerified); err != nil {
				return err
			}
			return nil
		},
	}
}

func (c *defaultRepository) updateEmail(uid auth.UserId, newEmail string, verified bool) error {
	const op = "repositories.auth.postgresRepository.updateEmail"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	query := `UPDATE credentials SET email = $2, emailVerified = $3 WHERE userId = $1;`
	_, err := c.db.Exec(query, string(uid), newEmail, verified)
	if err != nil {
		c.logger.LogInfo("%s: failed to perform query err: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, uid)
	return nil
}

func (c *defaultRepository) GetUserInfo(uid auth.UserId) (auth.UserInfo, error) {
	const op = "repositories.auth.postgresRepository.GetUserInfo"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	query := `SELECT email, password, emailVerified FROM credentials WHERE userId = $1;`
	row := c.db.QueryRow(query, string(uid))
	result := auth.UserInfo{
		UserId: auth.UserId(uid),
	}
	if err := row.Scan(&result.Email, &result.PasswordHash, &result.EmailVerified); err != nil {
		c.logger.LogInfo("%s: failed to perform scan err: %v", op, err)
		return auth.UserInfo{}, err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, uid)
	return result, nil
}
