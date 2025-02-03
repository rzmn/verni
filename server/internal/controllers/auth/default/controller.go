package defaultController

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"verni/internal/common"
	openapi "verni/internal/openapi/go"
	"verni/internal/services/formatValidation"
	"verni/internal/services/jwt"
	"verni/internal/services/logging"

	"verni/internal/controllers/auth"

	authRepository "verni/internal/repositories/auth"
	operationsRepository "verni/internal/repositories/operations"
	pushNotificationsRepository "verni/internal/repositories/pushNotifications"

	"github.com/google/uuid"
)

type AuthRepository authRepository.Repository
type OperationsRepository operationsRepository.Repository
type PushTokensRepository pushNotificationsRepository.Repository

func New(
	authRepository AuthRepository,
	operationsRepository OperationsRepository,
	pushTokensRepository PushTokensRepository,
	jwtService jwt.Service,
	formatValidationService formatValidation.Service,
	logger logging.Service,
) auth.Controller {
	return &defaultController{
		authRepository:          authRepository,
		operationsRepository:    operationsRepository,
		pushTokensRepository:    pushTokensRepository,
		jwtService:              jwtService,
		formatValidationService: formatValidationService,
		logger:                  logger,
	}
}

type defaultController struct {
	authRepository          AuthRepository
	operationsRepository    OperationsRepository
	pushTokensRepository    PushTokensRepository
	jwtService              jwt.Service
	formatValidationService formatValidation.Service
	logger                  logging.Service
}

func (c *defaultController) Signup(device auth.DeviceId, email string, password auth.Password) (auth.StartupData, error) {
	const op = "auth.defaultController.Signup"
	c.logger.LogInfo("%s: start", op)

	if err := c.formatValidationService.ValidateEmailFormat(email); err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: validating email format: %w", op, auth.BadFormat)
	}
	if err := c.formatValidationService.ValidatePasswordFormat(string(password)); err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: validating password format: %w", op, auth.BadFormat)
	}
	if err := c.formatValidationService.ValidateDeviceIdFormat(string(device)); err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: validating device id format: %w", op, auth.BadFormat)
	}

	uidAccosiatedWithEmail, err := c.authRepository.GetUserIdByEmail(email)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: getting uid by credentials from db: %w", op, err)
	}
	if uidAccosiatedWithEmail != nil {
		return auth.StartupData{}, fmt.Errorf("%s: checking if credentials are already taken: %w", op, auth.AlreadyTaken)
	}

	subject := jwt.Subject{
		User:   jwt.UserId(uuid.New().String()),
		Device: jwt.DeviceId(device),
	}
	accessToken, err := c.jwtService.IssueAccessToken(subject)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: issuing access token: %w", op, err)
	}

	refreshToken, err := c.jwtService.IssueRefreshToken(subject)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: issuing refresh token: %w", op, err)
	}

	displayName := strings.Split(email, "@")[0]
	startupOperations := []openapi.SomeOperation{
		{
			OperationId: uuid.New().String(),
			CreatedAt:   time.Now().UnixMilli(),
			AuthorId:    string(subject.User),
			CreateUser: openapi.CreateUserOperationCreateUser{
				UserId:      string(subject.User),
				DisplayName: displayName,
			},
		},
	}
	createOperationTransaction := c.operationsRepository.Push(
		common.Map(startupOperations, func(operation openapi.SomeOperation) operationsRepository.Operation {
			return operationsRepository.CreateOperation(operation)
		}),
		operationsRepository.UserId(subject.User),
		operationsRepository.DeviceId(subject.Device),
		false,
	)
	if err := createOperationTransaction.Perform(); err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: creating operation: %w", op, err)
	}

	createSessionTransaction := c.authRepository.UpdateRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		string(refreshToken),
	)
	if err := createSessionTransaction.Perform(); err != nil {
		createOperationTransaction.Rollback()
		return auth.StartupData{}, fmt.Errorf("%s: creating session: %w", op, err)
	}

	createProfileTransaction := c.authRepository.CreateUser(
		authRepository.UserId(subject.User),
		email,
		string(password),
	)
	if err := createProfileTransaction.Perform(); err != nil {
		createSessionTransaction.Rollback()
		createOperationTransaction.Rollback()
		return auth.StartupData{}, fmt.Errorf("%s: creating profile: %w", op, err)
	}

	c.logger.LogInfo("%s: success", op)
	return auth.StartupData{
		Session: auth.Session{
			Id:           auth.UserId(subject.User),
			AccessToken:  string(accessToken),
			RefreshToken: string(refreshToken),
		},
		Operations: startupOperations,
	}, nil
}

func (c *defaultController) Login(device auth.DeviceId, email string, password auth.Password) (auth.StartupData, error) {
	const op = "auth.defaultController.Login"
	c.logger.LogInfo("%s: start", op)

	valid, err := c.authRepository.CheckCredentials(email, string(password))
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: checking credentials matched: %w", op, err)
	}
	if !valid {
		return auth.StartupData{}, fmt.Errorf("%s: checking credentials matched: %w", op, auth.WrongCredentials)
	}

	uid, err := c.authRepository.GetUserIdByEmail(email)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: getting user by email: %w", op, err)
	}
	if uid == nil {
		return auth.StartupData{}, fmt.Errorf("%s: getting user by email: %w", op, auth.NoSuchEntity)
	}

	subject := jwt.Subject{
		User:   jwt.UserId(*uid),
		Device: jwt.DeviceId(device),
	}
	accessToken, err := c.jwtService.IssueAccessToken(subject)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: issuing access token: %w", op, err)
	}

	refreshToken, err := c.jwtService.IssueRefreshToken(subject)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: issuing refresh token: %w", op, err)
	}

	rawPulledOperations, err := c.operationsRepository.Pull(
		operationsRepository.UserId(subject.User),
		operationsRepository.DeviceId(subject.Device),
		true,
	)
	if err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: pulling operations for startup: %w", op, err)
	}

	startupOperations := make([]openapi.SomeOperation, len(rawPulledOperations))
	for index, operation := range rawPulledOperations {
		data, err := operation.Payload.Data()
		if err != nil {
			return auth.StartupData{}, fmt.Errorf("%s: getting data from operation %v: %w", op, operation, err)
		}
		var converted openapi.SomeOperation
		if err := json.Unmarshal(data, &converted); err != nil {
			return auth.StartupData{}, fmt.Errorf("%s: parsing operation from %v payload data: %w", op, operation, err)
		}
		startupOperations[index] = converted
	}

	transaction := c.authRepository.UpdateRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		string(refreshToken),
	)
	if err := transaction.Perform(); err != nil {
		return auth.StartupData{}, fmt.Errorf("%s: storing refresh token: %w", op, err)
	}

	c.logger.LogInfo("%s: success", op)
	return auth.StartupData{
		Session: auth.Session{
			Id:           auth.UserId(*uid),
			AccessToken:  string(accessToken),
			RefreshToken: string(refreshToken),
		},
		Operations: startupOperations,
	}, nil
}

func (c *defaultController) Refresh(refreshToken string) (auth.Session, error) {
	const op = "auth.defaultController.Refresh"
	c.logger.LogInfo("%s: start", op)

	if err := c.jwtService.ValidateRefreshToken(jwt.RefreshToken(refreshToken)); err != nil {
		if errors.Is(err, jwt.TokenExpired) {
			return auth.Session{}, fmt.Errorf("validating refresh token: %w", auth.TokenExpired)
		} else if errors.Is(err, jwt.BadToken) {
			return auth.Session{}, fmt.Errorf("validating refresh token: %w", auth.BadFormat)
		} else {
			return auth.Session{}, fmt.Errorf("validating refresh token: %w", err)
		}
	}

	subject, err := c.jwtService.GetRefreshTokenSubject(jwt.RefreshToken(refreshToken))
	if err != nil {
		return auth.Session{}, fmt.Errorf("%s: getting refresh token subject: %w", op, err)
	}

	valid, err := c.authRepository.CheckRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		refreshToken,
	)
	if err != nil {
		return auth.Session{}, fmt.Errorf("%s: checking refresh token: %w", op, err)
	}
	if !valid {
		return auth.Session{}, fmt.Errorf("%s: checking refresh token: %w", op, auth.WrongCredentials)
	}

	newAccessToken, err := c.jwtService.IssueAccessToken(subject)
	if err != nil {
		return auth.Session{}, fmt.Errorf("%s: issuing access token: %w", op, err)
	}

	newRefreshToken, err := c.jwtService.IssueRefreshToken(subject)
	if err != nil {
		return auth.Session{}, fmt.Errorf("%s: issuing refresh token: %w", op, err)
	}

	transaction := c.authRepository.UpdateRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		string(newRefreshToken),
	)
	if err := transaction.Perform(); err != nil {
		return auth.Session{}, fmt.Errorf("%s: storing new refresh token: %w", op, err)
	}

	c.logger.LogInfo("%s: success", op)
	return auth.Session{
		Id:           auth.UserId(subject.User),
		AccessToken:  string(newAccessToken),
		RefreshToken: string(newRefreshToken),
	}, nil
}

func (c *defaultController) CheckToken(accessToken string) (auth.UserDevice, error) {
	const op = "auth.defaultController.CheckToken"
	c.logger.LogInfo("%s: start", op)

	if err := c.jwtService.ValidateAccessToken(jwt.AccessToken(accessToken)); err != nil {
		if errors.Is(err, jwt.TokenExpired) {
			return auth.UserDevice{}, fmt.Errorf("%s: validating access token: %w", op, auth.TokenExpired)
		} else if errors.Is(err, jwt.BadToken) {
			return auth.UserDevice{}, fmt.Errorf("%s: validating access token: %w", op, auth.BadFormat)
		} else {
			return auth.UserDevice{}, fmt.Errorf("%s: validating access token: %w", op, err)
		}
	}

	subject, err := c.jwtService.GetAccessTokenSubject(jwt.AccessToken(accessToken))
	if err != nil {
		return auth.UserDevice{}, fmt.Errorf("%s: getting access token subject: %w", op, err)
	}

	exists, err := c.authRepository.IsSessionExists(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
	)
	if err != nil {
		return auth.UserDevice{}, fmt.Errorf("%s: checking session existence: %w", op, err)
	}
	if !exists {
		return auth.UserDevice{}, fmt.Errorf("%s: no session associated with access token: %w", op, auth.NoSuchEntity)
	}

	c.logger.LogInfo("%s: access token ok", op)
	return auth.UserDevice{
		User:   auth.UserId(subject.User),
		Device: auth.DeviceId(subject.Device),
	}, nil
}

func (c *defaultController) UpdateEmail(email string, user auth.UserId, device auth.DeviceId) error {
	const op = "auth.defaultController.UpdateEmail"
	c.logger.LogInfo("%s: start[id=%s]", op, user)

	if err := c.formatValidationService.ValidateEmailFormat(email); err != nil {
		return fmt.Errorf("%s: validating email format: %w", op, auth.BadFormat)
	}

	uidForNewEmail, err := c.authRepository.GetUserIdByEmail(email)
	if err != nil {
		return fmt.Errorf("%s: getting uid by email from db: %w", op, err)
	}
	if uidForNewEmail != nil {
		return fmt.Errorf("%s: checking if email is already taken: %w", op, auth.AlreadyTaken)
	}

	updateEmailTransaction := c.authRepository.UpdateEmail(authRepository.UserId(user), email)
	if err := updateEmailTransaction.Perform(); err != nil {
		return fmt.Errorf("%s: updating email: %w", op, err)
	}

	exclusiveSessionTransaction := c.authRepository.ExclusiveSession(
		authRepository.UserId(user),
		authRepository.DeviceId(device),
	)
	if err := exclusiveSessionTransaction.Perform(); err != nil {
		updateEmailTransaction.Rollback()
		return fmt.Errorf("%s: making an exclusive session: %w", op, err)
	}

	c.logger.LogInfo("%s: success[id=%s]", op, user)
	return nil
}

func (c *defaultController) UpdatePassword(oldPassword auth.Password, newPassword auth.Password, user auth.UserId, device auth.DeviceId) error {
	const op = "auth.defaultController.UpdatePassword"
	c.logger.LogInfo("%s: start[id=%s]", op, user)

	if err := c.formatValidationService.ValidatePasswordFormat(string(newPassword)); err != nil {
		return fmt.Errorf("%s: validating password format: %w", op, auth.BadFormat)
	}

	account, err := c.authRepository.GetUserInfo(authRepository.UserId(user))
	if err != nil {
		return fmt.Errorf("%s: getting profile info: %w", op, err)
	}

	passed, err := c.authRepository.CheckCredentials(account.Email, string(oldPassword))
	if err != nil {
		return fmt.Errorf("%s: checking password matches: %w", op, err)
	}
	if !passed {
		return fmt.Errorf("%s: old password is wrong: %w", op, auth.WrongCredentials)
	}

	updatePasswordTransaction := c.authRepository.UpdatePassword(
		authRepository.UserId(user),
		string(newPassword),
	)
	if err := updatePasswordTransaction.Perform(); err != nil {
		return fmt.Errorf("%s: updating password: %w", op, err)
	}

	exclusiveSessionTransaction := c.authRepository.ExclusiveSession(
		authRepository.UserId(user),
		authRepository.DeviceId(device),
	)
	if err := exclusiveSessionTransaction.Perform(); err != nil {
		updatePasswordTransaction.Rollback()
		return fmt.Errorf("%s: making an exclusive session: %w", op, err)
	}

	c.logger.LogInfo("%s: success[id=%s]", op, user)
	return nil
}

func (c *defaultController) RegisterForPushNotifications(pushToken string, user auth.UserId, device auth.DeviceId) error {
	const op = "auth.defaultController.RegisterForPushNotifications"
	c.logger.LogInfo("%s: start[id=%s]", op, user)

	storeTransaction := c.pushTokensRepository.StorePushToken(
		pushNotificationsRepository.UserId(user),
		pushNotificationsRepository.DeviceId(device),
		pushToken,
	)
	if err := storeTransaction.Perform(); err != nil {
		return fmt.Errorf("%s: storing push token: %w", op, err)
	}

	c.logger.LogInfo("%s: success[id=%s]", op, user)
	return nil
}
