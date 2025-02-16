package defaultRepository_test

import (
	"database/sql"
	"encoding/json"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	postgresDb "verni/internal/db/postgres"
	defaultRepository "verni/internal/repositories/verification/default"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
	defaultPathProvider "verni/internal/services/pathProvider/default"
)

var testConfig postgresDb.PostgresConfig

func TestMain(m *testing.M) {
	code := m.Run()
	os.Exit(code)
}

func setupTestDB(t *testing.T) *sql.DB {
	logger := standartOutputLoggingService.New()
	pathProvider := defaultPathProvider.New(logger)
	path := pathProvider.AbsolutePath("./config/test/postgres_storage.json")

	configFile, err := os.ReadFile(path)
	require.NoError(t, err)

	err = json.Unmarshal(configFile, &testConfig)
	require.NoError(t, err)

	db, err := postgresDb.Postgres(testConfig, logger)
	require.NoError(t, err)

	// Clear test data
	_, err = db.Exec("DELETE FROM emailVerification")
	require.NoError(t, err)

	return db.(*sql.DB)
}

func TestRepository_StoreEmailVerificationCode(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("store new code", func(t *testing.T) {
		// Arrange
		email := "test1@example.com"
		code := "123456"

		// Act
		work := repo.StoreEmailVerificationCode(email, code)
		err := work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify code was stored
		storedCode, err := repo.GetEmailVerificationCode(email)
		assert.NoError(t, err)
		assert.NotNil(t, storedCode)
		assert.Equal(t, code, *storedCode)
	})

	t.Run("update existing code", func(t *testing.T) {
		// Arrange
		email := "test2@example.com"
		oldCode := "123456"
		newCode := "654321"

		// Store initial code
		work := repo.StoreEmailVerificationCode(email, oldCode)
		err := work.Perform()
		require.NoError(t, err)

		// Act - Update code
		work = repo.StoreEmailVerificationCode(email, newCode)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify new code was stored
		storedCode, err := repo.GetEmailVerificationCode(email)
		assert.NoError(t, err)
		assert.NotNil(t, storedCode)
		assert.Equal(t, newCode, *storedCode)
	})

	t.Run("rollback store", func(t *testing.T) {
		// Arrange
		email := "test3@example.com"
		oldCode := "123456"
		newCode := "654321"

		// Store initial code
		work := repo.StoreEmailVerificationCode(email, oldCode)
		err := work.Perform()
		require.NoError(t, err)

		// Act - Store new code and rollback
		work = repo.StoreEmailVerificationCode(email, newCode)
		err = work.Perform()
		require.NoError(t, err)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert - Should be back to old code
		storedCode, err := repo.GetEmailVerificationCode(email)
		assert.NoError(t, err)
		assert.NotNil(t, storedCode)
		assert.Equal(t, oldCode, *storedCode)
	})
}

func TestRepository_GetEmailVerificationCode(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("get existing code", func(t *testing.T) {
		// Arrange
		email := "test4@example.com"
		code := "123456"

		work := repo.StoreEmailVerificationCode(email, code)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		storedCode, err := repo.GetEmailVerificationCode(email)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, storedCode)
		assert.Equal(t, code, *storedCode)
	})

	t.Run("get non-existent code", func(t *testing.T) {
		// Act
		storedCode, err := repo.GetEmailVerificationCode("nonexistent@example.com")

		// Assert
		assert.NoError(t, err)
		assert.Nil(t, storedCode)
	})
}

func TestRepository_RemoveEmailVerificationCode(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("remove existing code", func(t *testing.T) {
		// Arrange
		email := "test5@example.com"
		code := "123456"

		work := repo.StoreEmailVerificationCode(email, code)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		work = repo.RemoveEmailVerificationCode(email)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify code was removed
		storedCode, err := repo.GetEmailVerificationCode(email)
		assert.NoError(t, err)
		assert.Nil(t, storedCode)
	})

	t.Run("remove non-existent code", func(t *testing.T) {
		// Act
		work := repo.RemoveEmailVerificationCode("nonexistent@example.com")
		err := work.Perform()

		// Assert
		assert.NoError(t, err)
	})

	t.Run("rollback remove", func(t *testing.T) {
		// Arrange
		email := "test6@example.com"
		code := "123456"

		work := repo.StoreEmailVerificationCode(email, code)
		err := work.Perform()
		require.NoError(t, err)

		// Act - Remove and rollback
		work = repo.RemoveEmailVerificationCode(email)
		err = work.Perform()
		require.NoError(t, err)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert - Code should be restored
		storedCode, err := repo.GetEmailVerificationCode(email)
		assert.NoError(t, err)
		assert.NotNil(t, storedCode)
		assert.Equal(t, code, *storedCode)
	})
}
