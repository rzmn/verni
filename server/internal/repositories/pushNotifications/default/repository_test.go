package defaultRepository_test

import (
	"database/sql"
	"encoding/json"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	postgresDb "verni/internal/db/postgres"
	"verni/internal/repositories/pushNotifications"
	defaultRepository "verni/internal/repositories/pushNotifications/default"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
	envBasedPathProvider "verni/internal/services/pathProvider/env"
)

var testConfig postgresDb.PostgresConfig

func setupTestDB(t *testing.T) *sql.DB {
	logger := standartOutputLoggingService.New()
	pathProvider := envBasedPathProvider.New(logger)
	path := pathProvider.AbsolutePath("./config/test/postgres_storage.json")

	configFile, err := os.ReadFile(path)
	require.NoError(t, err)

	err = json.Unmarshal(configFile, &testConfig)
	require.NoError(t, err)

	db, err := postgresDb.Postgres(testConfig, logger)
	require.NoError(t, err)

	// Clear test data
	_, err = db.Exec("DELETE FROM pushTokens")
	require.NoError(t, err)

	return db.(*sql.DB)
}

func TestRepository_StorePushToken(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("store new token", func(t *testing.T) {
		// Arrange
		userId := pushNotifications.UserId("test-user-1")
		deviceId := pushNotifications.DeviceId("device-1")
		token := "push-token-123"

		// Act
		work := repo.StorePushToken(userId, deviceId, token)
		err := work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify token was stored
		storedToken, err := repo.GetPushToken(userId, deviceId)
		assert.NoError(t, err)
		assert.NotNil(t, storedToken)
		assert.Equal(t, token, *storedToken)
	})

	t.Run("update existing token", func(t *testing.T) {
		// Arrange
		userId := pushNotifications.UserId("test-user-2")
		deviceId := pushNotifications.DeviceId("device-2")
		token1 := "push-token-1"
		token2 := "push-token-2"

		// Store initial token
		work := repo.StorePushToken(userId, deviceId, token1)
		err := work.Perform()
		require.NoError(t, err)

		// Act - Update token
		work = repo.StorePushToken(userId, deviceId, token2)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify token was updated
		storedToken, err := repo.GetPushToken(userId, deviceId)
		assert.NoError(t, err)
		assert.NotNil(t, storedToken)
		assert.Equal(t, token2, *storedToken)
	})
}

func TestRepository_GetPushToken(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("get existing token", func(t *testing.T) {
		// Arrange
		userId := pushNotifications.UserId("test-user-3")
		deviceId := pushNotifications.DeviceId("device-3")
		token := "push-token-123"

		work := repo.StorePushToken(userId, deviceId, token)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		storedToken, err := repo.GetPushToken(userId, deviceId)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, storedToken)
		assert.Equal(t, token, *storedToken)
	})

	t.Run("get non-existent token", func(t *testing.T) {
		// Act
		token, err := repo.GetPushToken("nonexistent-user", "nonexistent-device")

		// Assert
		assert.NoError(t, err)
		assert.Nil(t, token)
	})
}

func TestRepository_StorePushToken_Rollback(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("rollback new token", func(t *testing.T) {
		// Arrange
		userId := pushNotifications.UserId("test-user-4")
		deviceId := pushNotifications.DeviceId("device-4")
		token := "push-token-123"

		// Act
		work := repo.StorePushToken(userId, deviceId, token)
		err := work.Perform()
		require.NoError(t, err)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert
		storedToken, err := repo.GetPushToken(userId, deviceId)
		assert.NoError(t, err)
		assert.Nil(t, storedToken)
	})

	t.Run("rollback token update", func(t *testing.T) {
		// Arrange
		userId := pushNotifications.UserId("test-user-5")
		deviceId := pushNotifications.DeviceId("device-5")
		token1 := "push-token-1"
		token2 := "push-token-2"

		// Store initial token
		work := repo.StorePushToken(userId, deviceId, token1)
		err := work.Perform()
		require.NoError(t, err)

		// Act - Update and rollback
		work = repo.StorePushToken(userId, deviceId, token2)
		err = work.Perform()
		require.NoError(t, err)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert - Should be back to token1
		storedToken, err := repo.GetPushToken(userId, deviceId)
		assert.NoError(t, err)
		assert.NotNil(t, storedToken)
		assert.Equal(t, token1, *storedToken)
	})
}

func TestMain(m *testing.M) {
	// Setup code (create database, tables, etc.)
	code := m.Run()
	// Cleanup code
	os.Exit(code)
}
