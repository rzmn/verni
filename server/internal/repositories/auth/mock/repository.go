package auth_mock

import (
	"verni/internal/repositories"
	"verni/internal/repositories/auth"
)

type RepositoryMock struct {
	CreateUserImpl             func(user auth.UserId, email string, password string) repositories.UnitOfWork
	MarkUserEmailValidatedImpl func(user auth.UserId) repositories.UnitOfWork
	IsUserExistsImpl           func(user auth.UserId) (bool, error)
	IsSessionExistsImpl        func(user auth.UserId, device auth.DeviceId) (bool, error)
	ExclusiveSessionImpl       func(user auth.UserId, device auth.DeviceId) repositories.UnitOfWork
	CheckCredentialsImpl       func(email string, password string) (bool, error)
	GetUserIdByEmailImpl       func(email string) (*auth.UserId, error)
	UpdateRefreshTokenImpl     func(user auth.UserId, device auth.DeviceId, token string) repositories.UnitOfWork
	CheckRefreshTokenImpl      func(user auth.UserId, device auth.DeviceId, token string) (bool, error)
	UpdatePasswordImpl         func(user auth.UserId, newPassword string) repositories.UnitOfWork
	UpdateEmailImpl            func(user auth.UserId, newEmail string) repositories.UnitOfWork
	GetUserInfoImpl            func(user auth.UserId) (auth.UserInfo, error)
}

func (c *RepositoryMock) CreateUser(user auth.UserId, email string, password string) repositories.UnitOfWork {
	return c.CreateUserImpl(user, email, password)
}

func (c *RepositoryMock) MarkUserEmailValidated(user auth.UserId) repositories.UnitOfWork {
	return c.MarkUserEmailValidatedImpl(user)
}

func (c *RepositoryMock) IsUserExists(user auth.UserId) (bool, error) {
	return c.IsUserExistsImpl(user)
}

func (c *RepositoryMock) IsSessionExists(user auth.UserId, device auth.DeviceId) (bool, error) {
	return c.IsSessionExistsImpl(user, device)
}

func (c *RepositoryMock) ExclusiveSession(user auth.UserId, device auth.DeviceId) repositories.UnitOfWork {
	return c.ExclusiveSessionImpl(user, device)
}

func (c *RepositoryMock) CheckCredentials(email string, password string) (bool, error) {
	return c.CheckCredentialsImpl(email, password)
}

func (c *RepositoryMock) GetUserIdByEmail(email string) (*auth.UserId, error) {
	return c.GetUserIdByEmailImpl(email)
}

func (c *RepositoryMock) UpdateRefreshToken(user auth.UserId, device auth.DeviceId, token string) repositories.UnitOfWork {
	return c.UpdateRefreshTokenImpl(user, device, token)
}

func (c *RepositoryMock) CheckRefreshToken(user auth.UserId, device auth.DeviceId, token string) (bool, error) {
	return c.CheckRefreshTokenImpl(user, device, token)
}

func (c *RepositoryMock) UpdatePassword(user auth.UserId, newPassword string) repositories.UnitOfWork {
	return c.UpdatePasswordImpl(user, newPassword)
}

func (c *RepositoryMock) UpdateEmail(user auth.UserId, newEmail string) repositories.UnitOfWork {
	return c.UpdateEmailImpl(user, newEmail)
}

func (c *RepositoryMock) GetUserInfo(user auth.UserId) (auth.UserInfo, error) {
	return c.GetUserInfoImpl(user)
}
