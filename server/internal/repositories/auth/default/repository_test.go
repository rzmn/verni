package defaultRepository_test

import (
	"database/sql"
	"encoding/json"
	"os"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	postgresDb "verni/internal/db/postgres"
	"verni/internal/repositories/auth"
	defaultRepository "verni/internal/repositories/auth/default"
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
	_, err = db.Exec("DELETE FROM refreshTokens")
	require.NoError(t, err)
	_, err = db.Exec("DELETE FROM credentials")
	require.NoError(t, err)

	return db.(*sql.DB)
}

func TestRepository_CreateUser(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("successful user creation", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-1")
		email := "test1@example.com"
		password := "password123"

		// Act
		work := repo.CreateUser(userId, email, password)
		err := work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify user exists
		exists, err := repo.IsUserExists(userId)
		assert.NoError(t, err)
		assert.True(t, exists)

		// Verify credentials
		valid, err := repo.CheckCredentials(email, password)
		assert.NoError(t, err)
		assert.True(t, valid)
	})

	t.Run("duplicate email", func(t *testing.T) {
		// Arrange
		userId1 := auth.UserId("test-user-2")
		userId2 := auth.UserId("test-user-3")
		email := "test2@example.com"
		password := "password123"

		// Create first user
		work := repo.CreateUser(userId1, email, password)
		err := work.Perform()
		require.NoError(t, err)

		// Act - try to create second user with same email
		work = repo.CreateUser(userId2, email, password)
		err = work.Perform()

		// Assert
		assert.Error(t, err)
	})
}

func TestRepository_MarkUserEmailValidated(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("successful email validation", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-4")
		email := "test4@example.com"
		password := "password123"

		// Create user
		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		work = repo.MarkUserEmailValidated(userId)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify email is marked as validated
		info, err := repo.GetUserInfo(userId)
		assert.NoError(t, err)
		assert.True(t, info.EmailVerified)
	})
}

func TestRepository_CheckCredentials(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("valid credentials", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-5")
		email := "test5@example.com"
		password := "password123"

		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		valid, err := repo.CheckCredentials(email, password)

		// Assert
		assert.NoError(t, err)
		assert.True(t, valid)
	})

	t.Run("invalid password", func(t *testing.T) {
		// Arrange
		email := "test5@example.com"
		wrongPassword := "wrongpassword"

		// Act
		valid, err := repo.CheckCredentials(email, wrongPassword)

		// Assert
		assert.NoError(t, err)
		assert.False(t, valid)
	})

	t.Run("non-existent email", func(t *testing.T) {
		// Act
		valid, err := repo.CheckCredentials("nonexistent@example.com", "password123")

		// Assert
		assert.NoError(t, err)
		assert.False(t, valid)
	})
}

func TestRepository_RefreshToken(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("refresh token lifecycle", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-6")
		deviceId := auth.DeviceId("device-1")
		email := "test6@example.com"
		password := "password123"
		token := "refresh-token-123"

		// Create user
		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		// Act - Update token
		work = repo.UpdateRefreshToken(userId, deviceId, token)
		err = work.Perform()
		assert.NoError(t, err)

		// Assert - Check token
		valid, err := repo.CheckRefreshToken(userId, deviceId, token)
		assert.NoError(t, err)
		assert.True(t, valid)

		// Assert - Session exists
		exists, err := repo.IsSessionExists(userId, deviceId)
		assert.NoError(t, err)
		assert.True(t, exists)
	})
}

func TestRepository_ExclusiveSession(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("exclusive session removes other sessions", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-7")
		device1 := auth.DeviceId("device-1")
		device2 := auth.DeviceId("device-2")
		email := "test7@example.com"
		password := "password123"

		// Create user and sessions
		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		work = repo.UpdateRefreshToken(userId, device1, "token1")
		err = work.Perform()
		require.NoError(t, err)

		work = repo.UpdateRefreshToken(userId, device2, "token2")
		err = work.Perform()
		require.NoError(t, err)

		// Act
		work = repo.ExclusiveSession(userId, device1)
		err = work.Perform()
		assert.NoError(t, err)

		// Assert
		exists, err := repo.IsSessionExists(userId, device1)
		assert.NoError(t, err)
		assert.True(t, exists)

		exists, err = repo.IsSessionExists(userId, device2)
		assert.NoError(t, err)
		assert.False(t, exists)
	})
}

func TestRepository_UpdateEmail(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("successful email update", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-8")
		oldEmail := "test8@example.com"
		newEmail := "test8new@example.com"
		password := "password123"

		work := repo.CreateUser(userId, oldEmail, password)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		work = repo.UpdateEmail(userId, newEmail)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		info, err := repo.GetUserInfo(userId)
		assert.NoError(t, err)
		assert.Equal(t, newEmail, info.Email)
		assert.False(t, info.EmailVerified)
	})
}

func TestRepository_UpdatePassword(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("successful password update", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-9")
		email := "test9@example.com"
		oldPassword := "password123"
		newPassword := "newpassword123"

		work := repo.CreateUser(userId, email, oldPassword)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		work = repo.UpdatePassword(userId, newPassword)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify old password no longer works
		valid, err := repo.CheckCredentials(email, oldPassword)
		assert.NoError(t, err)
		assert.False(t, valid)

		// Verify new password works
		valid, err = repo.CheckCredentials(email, newPassword)
		assert.NoError(t, err)
		assert.True(t, valid)
	})
}

func TestRepository_GetUserIdByEmail(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("existing user", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-10")
		email := "test10@example.com"
		password := "password123"

		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		foundId, err := repo.GetUserIdByEmail(email)

		// Assert
		assert.NoError(t, err)
		assert.NotNil(t, foundId)
		assert.Equal(t, userId, *foundId)
	})

	t.Run("non-existent user", func(t *testing.T) {
		// Act
		foundId, err := repo.GetUserIdByEmail("nonexistent@example.com")

		// Assert
		assert.NoError(t, err)
		assert.Nil(t, foundId)
	})
}

func TestRepository_MarkUserEmailValidated_Error(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("non-existent user", func(t *testing.T) {
		// Act
		work := repo.MarkUserEmailValidated("nonexistent-user")
		err := work.Perform()

		// Assert
		assert.Error(t, err)
	})

	t.Run("already validated email", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-11")
		email := "test11@example.com"
		password := "password123"

		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		// Validate first time
		work = repo.MarkUserEmailValidated(userId)
		err = work.Perform()
		require.NoError(t, err)

		// Act - Try to validate again
		work = repo.MarkUserEmailValidated(userId)
		err = work.Perform()

		// Assert - Should not return error, but should not change state
		assert.NoError(t, err)

		info, err := repo.GetUserInfo(userId)
		assert.NoError(t, err)
		assert.True(t, info.EmailVerified)
	})
}

func TestRepository_UpdateEmail_Error(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("duplicate email", func(t *testing.T) {
		// Arrange
		userId1 := auth.UserId("test-user-12")
		userId2 := auth.UserId("test-user-13")
		email1 := "test12@example.com"
		email2 := "test13@example.com"
		password := "password123"

		// Create first user
		work := repo.CreateUser(userId1, email1, password)
		err := work.Perform()
		require.NoError(t, err)

		// Create second user
		work = repo.CreateUser(userId2, email2, password)
		err = work.Perform()
		require.NoError(t, err)

		// Act - Try to update second user's email to first user's email
		work = repo.UpdateEmail(userId2, email1)
		err = work.Perform()

		// Assert
		assert.Error(t, err)

		// Verify email wasn't changed
		info, err := repo.GetUserInfo(userId2)
		assert.NoError(t, err)
		assert.Equal(t, email2, info.Email)
	})
}

func TestRepository_RefreshToken_Rollback(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("rollback refresh token update", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-14")
		deviceId := auth.DeviceId("device-1")
		email := "test14@example.com"
		password := "password123"
		token1 := "refresh-token-1"
		token2 := "refresh-token-2"

		// Create user and initial token
		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		work = repo.UpdateRefreshToken(userId, deviceId, token1)
		err = work.Perform()
		require.NoError(t, err)

		// Act - Update token and rollback
		work = repo.UpdateRefreshToken(userId, deviceId, token2)
		err = work.Perform()
		require.NoError(t, err)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert - Should be back to token1
		valid, err := repo.CheckRefreshToken(userId, deviceId, token1)
		assert.NoError(t, err)
		assert.True(t, valid)

		valid, err = repo.CheckRefreshToken(userId, deviceId, token2)
		assert.NoError(t, err)
		assert.False(t, valid)
	})
}

func TestRepository_GetUserInfo_Error(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("non-existent user", func(t *testing.T) {
		// Act
		_, err := repo.GetUserInfo("nonexistent-user")

		// Assert
		assert.Error(t, err)
	})
}

func TestRepository_ExclusiveSession_Rollback(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("rollback exclusive session", func(t *testing.T) {
		// Arrange
		userId := auth.UserId("test-user-15")
		device1 := auth.DeviceId("device-1")
		device2 := auth.DeviceId("device-2")
		email := "test15@example.com"
		password := "password123"

		// Create user and sessions
		work := repo.CreateUser(userId, email, password)
		err := work.Perform()
		require.NoError(t, err)

		work = repo.UpdateRefreshToken(userId, device1, "token1")
		err = work.Perform()
		require.NoError(t, err)

		work = repo.UpdateRefreshToken(userId, device2, "token2")
		err = work.Perform()
		require.NoError(t, err)

		// Act - Make exclusive and rollback
		work = repo.ExclusiveSession(userId, device1)
		err = work.Perform()
		require.NoError(t, err)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert - Both sessions should exist again
		exists, err := repo.IsSessionExists(userId, device1)
		assert.NoError(t, err)
		assert.True(t, exists)

		exists, err = repo.IsSessionExists(userId, device2)
		assert.NoError(t, err)
		assert.True(t, exists)
	})
}

func TestMain(m *testing.M) {
	// Setup code (create database, tables, etc.)
	code := m.Run()
	// Cleanup code
	os.Exit(code)
}
