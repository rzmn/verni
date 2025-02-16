package defaultController_test

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/assert"

	"verni/internal/controllers/verification"
	defaultController "verni/internal/controllers/verification/default"
	"verni/internal/repositories"
	authRepository "verni/internal/repositories/auth"
	authRepository_mock "verni/internal/repositories/auth/mock"
	verificationRepository_mock "verni/internal/repositories/verification/mock"
	emailSender_mock "verni/internal/services/emailSender/mock"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
)

func TestController_SendConfirmationCode(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful send confirmation code", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			StoreEmailVerificationCodeImpl: func(email string, code string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		emailService := &emailSender_mock.ServiceMock{
			SendImpl: func(subject string, email string) error {
				assert.Equal(t, userEmail, email)
				assert.Contains(t, subject, "Verification code")
				return nil
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, emailService, logger)

		// Act
		err := controller.SendConfirmationCode(userId)

		// Assert
		assert.NoError(t, err)
	})

	t.Run("user not found", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{}, errors.New("user not found")
			},
		}

		controller := defaultController.New(nil, authRepo, nil, logger)

		// Act
		err := controller.SendConfirmationCode("nonexistent-user")

		// Assert
		assert.Error(t, err)
	})

	t.Run("store code error", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			StoreEmailVerificationCodeImpl: func(email string, code string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return errors.New("store error") },
					Rollback: func() error { return nil },
				}
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, nil, logger)

		// Act
		err := controller.SendConfirmationCode(userId)

		// Assert
		assert.Error(t, err)
	})

	t.Run("email sending error", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			StoreEmailVerificationCodeImpl: func(email string, code string) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		emailService := &emailSender_mock.ServiceMock{
			SendImpl: func(subject string, email string) error {
				return errors.New("email sending failed")
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, emailService, logger)

		// Act
		err := controller.SendConfirmationCode(userId)

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, verification.CodeNotDelivered)
	})
}

func TestController_ConfirmEmail(t *testing.T) {
	logger := standartOutputLoggingService.New()

	t.Run("successful email confirmation", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"
		code := "123456"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
			MarkUserEmailValidatedImpl: func(user authRepository.UserId) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return nil },
					Rollback: func() error { return nil },
				}
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			GetEmailVerificationCodeImpl: func(email string) (*string, error) {
				return &code, nil
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, nil, logger)

		// Act
		err := controller.ConfirmEmail(userId, code)

		// Assert
		assert.NoError(t, err)
	})

	t.Run("user not found", func(t *testing.T) {
		// Arrange
		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{}, errors.New("user not found")
			},
		}

		controller := defaultController.New(nil, authRepo, nil, logger)

		// Act
		err := controller.ConfirmEmail("nonexistent-user", "123456")

		// Assert
		assert.Error(t, err)
	})

	t.Run("code not sent", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			GetEmailVerificationCodeImpl: func(email string) (*string, error) {
				return nil, nil
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, nil, logger)

		// Act
		err := controller.ConfirmEmail(userId, "123456")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, verification.CodeHasNotBeenSent)
	})

	t.Run("wrong confirmation code", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"
		storedCode := "123456"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			GetEmailVerificationCodeImpl: func(email string) (*string, error) {
				return &storedCode, nil
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, nil, logger)

		// Act
		err := controller.ConfirmEmail(userId, "wrong-code")

		// Assert
		assert.Error(t, err)
		assert.ErrorIs(t, err, verification.WrongConfirmationCode)
	})

	t.Run("mark email validated error", func(t *testing.T) {
		// Arrange
		userId := verification.UserId("test-user")
		userEmail := "test@example.com"
		code := "123456"

		authRepo := &authRepository_mock.RepositoryMock{
			GetUserInfoImpl: func(user authRepository.UserId) (authRepository.UserInfo, error) {
				return authRepository.UserInfo{
					UserId: authRepository.UserId(userId),
					Email:  userEmail,
				}, nil
			},
			MarkUserEmailValidatedImpl: func(user authRepository.UserId) repositories.UnitOfWork {
				return repositories.UnitOfWork{
					Perform:  func() error { return errors.New("validation error") },
					Rollback: func() error { return nil },
				}
			},
		}

		verificationRepo := &verificationRepository_mock.RepositoryMock{
			GetEmailVerificationCodeImpl: func(email string) (*string, error) {
				return &code, nil
			},
		}

		controller := defaultController.New(verificationRepo, authRepo, nil, logger)

		// Act
		err := controller.ConfirmEmail(userId, code)

		// Assert
		assert.Error(t, err)
	})
}
