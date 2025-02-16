package defaultController_test

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"

	"verni/internal/controllers/auth"
	defaultController "verni/internal/controllers/auth/default"
	"verni/internal/repositories"
	authRepository "verni/internal/repositories/auth"
	authRepository_mock "verni/internal/repositories/auth/mock"
	operationsRepository "verni/internal/repositories/operations"
	operationsRepository_mock "verni/internal/repositories/operations/mock"
	"verni/internal/repositories/pushNotifications"
	pushNotificationsRepository_mock "verni/internal/repositories/pushNotifications/mock"
	formatValidation_mock "verni/internal/services/formatValidation/mock"
	"verni/internal/services/jwt"
	jwt_mock "verni/internal/services/jwt/mock"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
)

func TestController_Signup(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful signup", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserIdByEmailImpl: func(email string) (*authRepository.UserId, error) {
				return nil, nil
			},
			UpdateRefreshTokenImpl: func(user authRepository.UserId, device authRepository.DeviceId, token string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
			CreateUserImpl: func(user authRepository.UserId, email string, password string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		opsRepo := &operationsRepository_mock.RepositoryMock{
			PushImpl: func(operations []operationsRepository.PushOperation, userId operationsRepository.UserId, deviceId operationsRepository.DeviceId, confirm bool) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		jwtService := &jwt_mock.ServiceMock{
			IssueAccessTokenImpl: func(subject jwt.Subject) (jwt.AccessToken, error) {
				return "access-token", nil
			},
			IssueRefreshTokenImpl: func(subject jwt.Subject) (jwt.RefreshToken, error) {
				return "refresh-token", nil
			},
		}

		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidateEmailFormatImpl:    func(email string) error { return nil },
			ValidatePasswordFormatImpl: func(password string) error { return nil },
			ValidateDeviceIdFormatImpl: func(id string) error { return nil },
		}

		pushRepo := &pushNotificationsRepository_mock.RepositoryMock{}

		controller := defaultController.New(
			authRepo,
			opsRepo,
			pushRepo,
			jwtService,
			formatValidationService,
			logger,
		)

		// Act
		result, err := controller.Signup("device-1", "test@example.com", "password123")

		// Assert
		assert.NoError(t, err)
		assert.NotEmpty(t, result.Session.Id)
		assert.Equal(t, "access-token", result.Session.AccessToken)
		assert.Equal(t, "refresh-token", result.Session.RefreshToken)
		assert.Len(t, result.Operations, 1)
		assert.Equal(t, "test", result.Operations[0].CreateUser.DisplayName)
	})

	t.Run("email already taken", func(t *testing.T) {
		// Arrange
		existingUserId := authRepository.UserId("existing-user")
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserIdByEmailImpl: func(email string) (*authRepository.UserId, error) {
				return &existingUserId, nil
			},
		}

		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidateEmailFormatImpl:    func(email string) error { return nil },
			ValidatePasswordFormatImpl: func(password string) error { return nil },
			ValidateDeviceIdFormatImpl: func(id string) error { return nil },
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			nil,
			formatValidationService,
			logger,
		)

		// Act
		_, err := controller.Signup("device-1", "test@example.com", "password123")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.AlreadyTaken)
	})

	t.Run("invalid email format", func(t *testing.T) {
		// Arrange
		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidateEmailFormatImpl: func(email string) error {
				return errors.New("invalid email")
			},
			ValidatePasswordFormatImpl: func(password string) error { return nil },
			ValidateDeviceIdFormatImpl: func(id string) error { return nil },
		}

		controller := defaultController.New(
			nil,
			nil,
			nil,
			nil,
			formatValidationService,
			logger,
		)

		// Act
		_, err := controller.Signup("device-1", "invalid-email", "password123")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.BadFormat)
	})
}

func TestController_Login(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful login", func(t *testing.T) {
		// Arrange
		userId := authRepository.UserId("test-user")
		authRepo := &authRepository_mock.RepositoryMock{
			CheckCredentialsImpl: func(email string, password string) (bool, error) {
				return true, nil
			},
			GetUserIdByEmailImpl: func(email string) (*authRepository.UserId, error) {
				return &userId, nil
			},
			UpdateRefreshTokenImpl: func(user authRepository.UserId, device authRepository.DeviceId, token string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		opsRepo := &operationsRepository_mock.RepositoryMock{
			PullImpl: func(userId operationsRepository.UserId, deviceId operationsRepository.DeviceId, operationType operationsRepository.OperationType) ([]operationsRepository.Operation, error) {
				return []operationsRepository.Operation{}, nil
			},
		}

		jwtService := &jwt_mock.ServiceMock{
			IssueAccessTokenImpl: func(subject jwt.Subject) (jwt.AccessToken, error) {
				return "access-token", nil
			},
			IssueRefreshTokenImpl: func(subject jwt.Subject) (jwt.RefreshToken, error) {
				return "refresh-token", nil
			},
		}

		controller := defaultController.New(
			authRepo,
			opsRepo,
			nil,
			jwtService,
			nil,
			logger,
		)

		// Act
		result, err := controller.Login("device-1", "test@example.com", "password123")

		// Assert
		assert.NoError(t, err)
		assert.Equal(t, auth.UserId(userId), result.Session.Id)
		assert.Equal(t, "access-token", result.Session.AccessToken)
		assert.Equal(t, "refresh-token", result.Session.RefreshToken)
	})

	t.Run("wrong credentials", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			CheckCredentialsImpl: func(email string, password string) (bool, error) {
				return false, nil
			},
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			nil,
			nil,
			logger,
		)

		// Act
		_, err := controller.Login("device-1", "test@example.com", "wrong-password")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.WrongCredentials)
	})
}

func TestController_Refresh(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful token refresh", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			CheckRefreshTokenImpl: func(user authRepository.UserId, device authRepository.DeviceId, token string) (bool, error) {
				return true, nil
			},
			UpdateRefreshTokenImpl: func(user authRepository.UserId, device authRepository.DeviceId, token string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		jwtService := &jwt_mock.ServiceMock{
			ValidateRefreshTokenImpl: func(token jwt.RefreshToken) error {
				return nil
			},
			GetRefreshTokenSubjectImpl: func(token jwt.RefreshToken) (jwt.Subject, error) {
				return jwt.Subject{
					User:   "test-user",
					Device: "device-1",
				}, nil
			},
			IssueAccessTokenImpl: func(subject jwt.Subject) (jwt.AccessToken, error) {
				return "new-access-token", nil
			},
			IssueRefreshTokenImpl: func(subject jwt.Subject) (jwt.RefreshToken, error) {
				return "new-refresh-token", nil
			},
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			jwtService,
			nil,
			logger,
		)

		// Act
		result, err := controller.Refresh("old-refresh-token")

		// Assert
		assert.NoError(t, err)
		assert.Equal(t, auth.UserId("test-user"), result.Id)
		assert.Equal(t, "new-access-token", result.AccessToken)
		assert.Equal(t, "new-refresh-token", result.RefreshToken)
	})

	t.Run("expired refresh token", func(t *testing.T) {
		// Arrange
		jwtService := &jwt_mock.ServiceMock{
			ValidateRefreshTokenImpl: func(token jwt.RefreshToken) error {
				return jwt.TokenExpired
			},
		}

		controller := defaultController.New(
			nil,
			nil,
			nil,
			jwtService,
			nil,
			logger,
		)

		// Act
		_, err := controller.Refresh("expired-token")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.TokenExpired)
	})
}

func TestController_CheckToken(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("valid access token", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			IsSessionExistsImpl: func(user authRepository.UserId, device authRepository.DeviceId) (bool, error) {
				return true, nil
			},
		}

		jwtService := &jwt_mock.ServiceMock{
			ValidateAccessTokenImpl: func(token jwt.AccessToken) error {
				return nil
			},
			GetAccessTokenSubjectImpl: func(token jwt.AccessToken) (jwt.Subject, error) {
				return jwt.Subject{
					User:   "test-user",
					Device: "device-1",
				}, nil
			},
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			jwtService,
			nil,
			logger,
		)

		// Act
		result, err := controller.CheckToken("valid-access-token")

		// Assert
		assert.NoError(t, err)
		assert.Equal(t, auth.UserId("test-user"), result.User)
		assert.Equal(t, auth.DeviceId("device-1"), result.Device)
	})

	t.Run("expired access token", func(t *testing.T) {
		// Arrange
		jwtService := &jwt_mock.ServiceMock{
			ValidateAccessTokenImpl: func(token jwt.AccessToken) error {
				return jwt.TokenExpired
			},
		}

		controller := defaultController.New(
			nil,
			nil,
			nil,
			jwtService,
			nil,
			logger,
		)

		// Act
		_, err := controller.CheckToken("expired-token")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.TokenExpired)
	})
}

func TestController_UpdateEmail(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful email update", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserIdByEmailImpl: func(email string) (*authRepository.UserId, error) {
				return nil, nil
			},
			UpdateEmailImpl: func(user authRepository.UserId, newEmail string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
			ExclusiveSessionImpl: func(user authRepository.UserId, device authRepository.DeviceId) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidateEmailFormatImpl: func(email string) error { return nil },
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			nil,
			formatValidationService,
			logger,
		)

		// Act
		err := controller.UpdateEmail("new@example.com", "test-user", "device-1")

		// Assert
		assert.NoError(t, err)
	})

	t.Run("email already taken", func(t *testing.T) {
		// Arrange
		existingUserId := authRepository.UserId("existing-user")
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserIdByEmailImpl: func(email string) (*authRepository.UserId, error) {
				return &existingUserId, nil
			},
		}

		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidateEmailFormatImpl: func(email string) error { return nil },
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			nil,
			formatValidationService,
			logger,
		)

		// Act
		err := controller.UpdateEmail("taken@example.com", "test-user", "device-1")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.AlreadyTaken)
	})
}

func TestController_UpdatePassword(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful password update", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: "test-user",
					Email:  "test@example.com",
				}, nil
			},
			CheckCredentialsImpl: func(email string, password string) (bool, error) {
				return true, nil
			},
			UpdatePasswordImpl: func(user authRepository.UserId, newPassword string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
			ExclusiveSessionImpl: func(user authRepository.UserId, device authRepository.DeviceId) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidatePasswordFormatImpl: func(password string) error { return nil },
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			nil,
			formatValidationService,
			logger,
		)

		// Act
		err := controller.UpdatePassword("old-password", "new-password", "test-user", "device-1")

		// Assert
		assert.NoError(t, err)
	})

	t.Run("wrong old password", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: "test-user",
					Email:  "test@example.com",
				}, nil
			},
			CheckCredentialsImpl: func(email string, password string) (bool, error) {
				return false, nil
			},
		}

		formatValidationService := &formatValidation_mock.ServiceMock{
			ValidatePasswordFormatImpl: func(password string) error { return nil },
		}

		controller := defaultController.New(
			authRepo,
			nil,
			nil,
			nil,
			formatValidationService,
			logger,
		)

		// Act
		err := controller.UpdatePassword("wrong-password", "new-password", "test-user", "device-1")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, auth.WrongCredentials)
	})
}

func TestController_RegisterForPushNotifications(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful push token registration", func(t *testing.T) {
		// Arrange
		pushRepo := &pushNotificationsRepository_mock.RepositoryMock{
			StorePushTokenImpl: func(user pushNotifications.UserId, device pushNotifications.DeviceId, token string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		controller := defaultController.New(
			nil,
			nil,
			pushRepo,
			nil,
			nil,
			logger,
		)

		// Act
		err := controller.RegisterForPushNotifications("push-token", "test-user", "device-1")

		// Assert
		assert.NoError(t, err)
	})
}
