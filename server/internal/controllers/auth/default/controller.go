package defaultController

import (
	"errors"
	"fmt"
	"strings"
	"time"

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

func (c *defaultController) Signup(device auth.DeviceId, email string, password auth.Password) (auth.Session, error) {
	const op = "auth.defaultController.Signup"
	c.logger.LogInfo("%s: start", op)
	if err := c.formatValidationService.ValidateEmailFormat(email); err != nil {
		c.logger.LogInfo("%s: wrong email format err: %v", op, err)
		return auth.Session{}, fmt.Errorf("validating email format: %w", auth.BadFormat)
	}
	if err := c.formatValidationService.ValidatePasswordFormat(string(password)); err != nil {
		c.logger.LogInfo("%s: wrong password format err: %v", op, err)
		return auth.Session{}, fmt.Errorf("validating password format: %w", auth.BadFormat)
	}
	if err := c.formatValidationService.ValidateDeviceIdFormat(string(device)); err != nil {
		c.logger.LogInfo("%s: wrong device id format err: %v", op, err)
		return auth.Session{}, fmt.Errorf("validating device id format: %w", auth.BadFormat)
	}
	uidAccosiatedWithEmail, err := c.authRepository.GetUserIdByEmail(email)
	if err != nil {
		err := fmt.Errorf("getting uid by credentials from db: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	if uidAccosiatedWithEmail != nil {
		c.logger.LogInfo("%s: already has an uid accosiated with credentials", op)
		return auth.Session{}, fmt.Errorf("checking if credentials are already taken: %w", auth.AlreadyTaken)
	}
	subject := jwt.Subject{
		User:   jwt.UserId(uuid.New().String()),
		Device: jwt.DeviceId(device),
	}
	accessToken, err := c.jwtService.IssueAccessToken(subject)
	if err != nil {
		err := fmt.Errorf("issuing access token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	refreshToken, err := c.jwtService.IssueRefreshToken(subject)
	if err != nil {
		err := fmt.Errorf("issuing refresh token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	displayName := strings.Split(email, "@")[0]
	createOperationTransaction := c.operationsRepository.Push(
		[]operationsRepository.Operation{
			operationsRepository.CreateOperation(
				openapi.SomeOperation{
					OperationId: uuid.New().String(),
					CreatedAt:   time.Now().UnixMilli(),
					AuthorId:    string(subject.User),
					CreateUser: openapi.CreateUserOperationCreateUser{
						UserId:      string(subject.User),
						DisplayName: displayName,
					},
				},
			),
		},
		operationsRepository.UserId(subject.User),
		operationsRepository.DeviceId(subject.Device),
	)
	if err := createOperationTransaction.Perform(); err != nil {
		err := fmt.Errorf("creating operation: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	createSessionTransaction := c.authRepository.UpdateRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		string(refreshToken),
	)
	if err := createSessionTransaction.Perform(); err != nil {
		createOperationTransaction.Rollback()
		err := fmt.Errorf("creating session: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	createProfileTransaction := c.authRepository.CreateUser(
		authRepository.UserId(subject.User),
		email,
		string(password),
	)
	if err := createProfileTransaction.Perform(); err != nil {
		createSessionTransaction.Rollback()
		createOperationTransaction.Rollback()
		err := fmt.Errorf("creating profile: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	c.logger.LogInfo("%s: success", op)
	return auth.Session{
		Id:           auth.UserId(subject.User),
		AccessToken:  string(accessToken),
		RefreshToken: string(refreshToken),
	}, nil
}

func (c *defaultController) Login(device auth.DeviceId, email string, password auth.Password) (auth.Session, error) {
	const op = "auth.defaultController.Login"
	c.logger.LogInfo("%s: start", op)
	valid, err := c.authRepository.CheckCredentials(email, string(password))
	if err != nil {
		c.logger.LogInfo("%s: credentials check failed err: %v", op, err)
		return auth.Session{}, fmt.Errorf("checking credentials matched: %w", err)
	}
	if !valid {
		c.logger.LogInfo("%s: credentials are wrong", op)
		return auth.Session{}, fmt.Errorf("checking credentials matched: %w", auth.WrongCredentials)
	}
	uid, err := c.authRepository.GetUserIdByEmail(email)
	if err != nil {
		c.logger.LogInfo("%s: getting uid by credentials in db failed err: %v", op, err)
		return auth.Session{}, fmt.Errorf("getting user by email: %w", err)
	}
	if uid == nil {
		c.logger.LogInfo("%s: no uid accosiated with credentials", op)
		return auth.Session{}, fmt.Errorf("getting user by email: %w", auth.NoSuchEntity)
	}
	subject := jwt.Subject{
		User:   jwt.UserId(*uid),
		Device: jwt.DeviceId(device),
	}
	accessToken, err := c.jwtService.IssueAccessToken(subject)
	if err != nil {
		err := fmt.Errorf("issuing access token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	refreshToken, err := c.jwtService.IssueRefreshToken(subject)
	if err != nil {
		err := fmt.Errorf("issuing refresh token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	transaction := c.authRepository.UpdateRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		string(refreshToken),
	)
	if err := transaction.Perform(); err != nil {
		err := fmt.Errorf("storing refresh token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	c.logger.LogInfo("%s: success", op)
	return auth.Session{
		Id:           auth.UserId(*uid),
		AccessToken:  string(accessToken),
		RefreshToken: string(refreshToken),
	}, nil
}

func (c *defaultController) Refresh(refreshToken string) (auth.Session, error) {
	const op = "auth.defaultController.Refresh"
	c.logger.LogInfo("%s: start", op)
	if err := c.jwtService.ValidateRefreshToken(jwt.RefreshToken(refreshToken)); err != nil {
		c.logger.LogInfo("%s: token validation failed err: %v", op, err)
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
		err := fmt.Errorf("getting refresh token subject: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	valid, err := c.authRepository.CheckRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		refreshToken,
	)
	if err != nil {
		err := fmt.Errorf("checking refresh token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	if !valid {
		c.logger.LogInfo("%s: existed refresh token does not match with provided token", op)
		return auth.Session{}, fmt.Errorf("checking refresh token: %w", auth.WrongCredentials)
	}
	newAccessToken, err := c.jwtService.IssueAccessToken(subject)
	if err != nil {
		err := fmt.Errorf("issuing access token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	newRefreshToken, err := c.jwtService.IssueRefreshToken(subject)
	if err != nil {
		err := fmt.Errorf("issuing refresh token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
	}
	transaction := c.authRepository.UpdateRefreshToken(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
		string(newRefreshToken),
	)
	if err := transaction.Perform(); err != nil {
		err := fmt.Errorf("storing new refresh token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.Session{}, err
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
		c.logger.LogInfo("%s: failed to validate token %v", op, err)
		if errors.Is(err, jwt.TokenExpired) {
			return auth.UserDevice{}, fmt.Errorf("validating access token: %w", auth.TokenExpired)
		} else if errors.Is(err, jwt.BadToken) {
			return auth.UserDevice{}, fmt.Errorf("validating access token: %w", auth.BadFormat)
		} else {
			return auth.UserDevice{}, fmt.Errorf("validating access token: %w", err)
		}
	}
	subject, err := c.jwtService.GetAccessTokenSubject(jwt.AccessToken(accessToken))
	if err != nil {
		err := fmt.Errorf("getting access token subject: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.UserDevice{}, err
	}
	exists, err := c.authRepository.IsSessionExists(
		authRepository.UserId(subject.User),
		authRepository.DeviceId(subject.Device),
	)
	if err != nil {
		err := fmt.Errorf("checking session existence: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return auth.UserDevice{}, err
	}
	if !exists {
		c.logger.LogInfo("%s: no session accosiated with access token", op)
		return auth.UserDevice{}, fmt.Errorf("getting session by subject: %w", auth.NoSuchEntity)
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
		c.logger.LogInfo("%s: wrong email format err: %v", op, err)
		return fmt.Errorf("validating email format: %w", auth.BadFormat)
	}
	uidForNewEmail, err := c.authRepository.GetUserIdByEmail(email)
	if err != nil {
		err := fmt.Errorf("getting uid by email from db: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	if uidForNewEmail != nil {
		c.logger.LogInfo("%s: email is already taken", op)
		return fmt.Errorf("checking if email is already taken: %w", auth.AlreadyTaken)
	}
	updateEmailTransaction := c.authRepository.UpdateEmail(authRepository.UserId(user), email)
	if err := updateEmailTransaction.Perform(); err != nil {
		err := fmt.Errorf("updating email: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	exclusiveSessionTransaction := c.authRepository.ExclusiveSession(
		authRepository.UserId(user),
		authRepository.DeviceId(device),
	)
	if err := exclusiveSessionTransaction.Perform(); err != nil {
		updateEmailTransaction.Rollback()
		err := fmt.Errorf("making an exclusive session: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[id=%s]", op, user)
	return nil
}

func (c *defaultController) UpdatePassword(oldPassword auth.Password, newPassword auth.Password, user auth.UserId, device auth.DeviceId) error {
	const op = "auth.defaultController.UpdatePassword"
	c.logger.LogInfo("%s: start[id=%s]", op, user)
	if err := c.formatValidationService.ValidatePasswordFormat(string(newPassword)); err != nil {
		c.logger.LogInfo("%s: wrong password format err: %v", op, err)
		return fmt.Errorf("validating password format: %w", auth.BadFormat)
	}
	account, err := c.authRepository.GetUserInfo(authRepository.UserId(user))
	if err != nil {
		err := fmt.Errorf("getting profile info: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	passed, err := c.authRepository.CheckCredentials(account.Email, string(oldPassword))
	if err != nil {
		err := fmt.Errorf("checking password matches: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	if !passed {
		c.logger.LogInfo("%s: old password is wrong", op)
		return fmt.Errorf("checking password matches: %w", auth.WrongCredentials)
	}
	updatePasswordTransaction := c.authRepository.UpdatePassword(
		authRepository.UserId(user),
		string(newPassword),
	)
	if err := updatePasswordTransaction.Perform(); err != nil {
		err := fmt.Errorf("updating password: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	exclusiveSessionTransaction := c.authRepository.ExclusiveSession(
		authRepository.UserId(user),
		authRepository.DeviceId(device),
	)
	if err := exclusiveSessionTransaction.Perform(); err != nil {
		updatePasswordTransaction.Rollback()
		err := fmt.Errorf("making an exclusive session: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[id=%s]", op, user)
	return nil
}

func (c *defaultController) RegisterForPushNotifications(pushToken string, user auth.UserId, device auth.DeviceId) error {
	const op = "auth.defaultController.ConfirmEmail"
	c.logger.LogInfo("%s: start[id=%s]", op, user)
	storeTransaction := c.pushTokensRepository.StorePushToken(
		pushNotificationsRepository.UserId(user),
		pushNotificationsRepository.DeviceId(device),
		pushToken,
	)
	if err := storeTransaction.Perform(); err != nil {
		err := fmt.Errorf("storing push token: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[id=%s]", op, user)
	return nil
}
