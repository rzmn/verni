package defaultRepository

import (
	"database/sql"
	"fmt"
	"verni/internal/db"
	"verni/internal/repositories"
	"verni/internal/repositories/verification"
	"verni/internal/services/logging"
)

func New(db db.DB, logger logging.Service) verification.Repository {
	return &postgresRepository{
		db:     db,
		logger: logger,
	}
}

type postgresRepository struct {
	db     db.DB
	logger logging.Service
}

func (c *postgresRepository) StoreEmailVerificationCode(email string, code string) repositories.UnitOfWork {
	const op = "repositories.verification.defaultRepository.StoreEmailVerificationCode"

	currentCode, err := c.GetEmailVerificationCode(email)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current code: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.UnitOfWork{
		Perform: func() error {
			return c.storeEmailVerificationCode(email, code)
		},
		Rollback: func() error {
			if currentCode == nil {
				return c.removeEmailVerificationCode(email)
			}
			return c.storeEmailVerificationCode(email, *currentCode)
		},
	}
}

func (c *postgresRepository) storeEmailVerificationCode(email string, code string) error {
	const op = "repositories.verification.defaultRepository.storeEmailVerificationCode"
	c.logger.LogInfo("%s: start[email=%s]", op, email)

	query := `
INSERT INTO emailVerification(email, code)
VALUES ($1, $2)
ON CONFLICT (email) DO UPDATE SET code = EXCLUDED.code;
`

	if _, err := c.db.Exec(query, email, code); err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[email=%s]", op, email)
	return nil
}

func (c *postgresRepository) GetEmailVerificationCode(email string) (*string, error) {
	const op = "repositories.verification.defaultRepository.GetEmailVerificationCode"
	c.logger.LogInfo("%s: start[email=%s]", op, email)

	query := `SELECT code FROM emailVerification WHERE email = $1;`
	row := c.db.QueryRow(query, email)

	var code string
	if err := row.Scan(&code); err != nil {
		if err == sql.ErrNoRows {
			c.logger.LogInfo("%s: no code found for email=%s", op, email)
			return nil, nil
		}
		return nil, fmt.Errorf("%s: failed to scan row for push token: %w", op, err)
	}

	c.logger.LogInfo("%s: success[email=%s]", op, email)
	return &code, nil
}

func (c *postgresRepository) RemoveEmailVerificationCode(email string) repositories.UnitOfWork {
	const op = "repositories.verification.defaultRepository.RemoveEmailVerificationCode"

	code, err := c.GetEmailVerificationCode(email)
	if err != nil {
		c.logger.LogInfo("%s: failed to get current code: %v", op, err)
		return repositories.UnitOfWork{
			Perform:  func() error { return err },
			Rollback: func() error { return err },
		}
	}

	return repositories.UnitOfWork{
		Perform: func() error {
			if code == nil {
				return nil
			}
			return c.removeEmailVerificationCode(email)
		},
		Rollback: func() error {
			if code == nil {
				return nil
			}
			return c.storeEmailVerificationCode(email, *code)
		},
	}
}

func (c *postgresRepository) removeEmailVerificationCode(email string) error {
	const op = "repositories.verification.defaultRepository.removeEmailVerificationCode"
	c.logger.LogInfo("%s: start[email=%s]", op, email)

	query := `DELETE FROM emailVerification WHERE email = $1;`
	if _, err := c.db.Exec(query, email); err != nil {
		return fmt.Errorf("%s: failed to perform query: %w", op, err)
	}

	c.logger.LogInfo("%s: success[email=%s]", op, email)
	return nil
}
