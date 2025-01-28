package auth_mock

import (
	"verni/internal/repositories"

	"verni/internal/repositories/auth"
)

type RepositoryMock struct {
	CreateUserImpl             func(uid auth.UserId, email string, password string, refreshToken string) repositories.Transaction
	MarkUserEmailValidatedImpl func(uid auth.UserId) repositories.Transaction
	IsUserExistsImpl           func(uid auth.UserId) (bool, error)
	CheckCredentialsImpl       func(email string, password string) (bool, error)
	GetUserIdByEmailImpl       func(email string) (*auth.UserId, error)
	UpdateRefreshTokenImpl     func(uid auth.UserId, token string) repositories.Transaction
	UpdatePasswordImpl         func(uid auth.UserId, newPassword string) repositories.Transaction
	UpdateEmailImpl            func(uid auth.UserId, newEmail string) repositories.Transaction
	GetUserInfoImpl            func(uid auth.UserId) (auth.UserInfo, error)
}

func (c *RepositoryMock) CreateUser(uid auth.UserId, email string, password string, refreshToken string) repositories.Transaction {
	return c.CreateUserImpl(uid, email, password, refreshToken)
}
func (c *RepositoryMock) MarkUserEmailValidated(uid auth.UserId) repositories.Transaction {
	return c.MarkUserEmailValidatedImpl(uid)
}
func (c *RepositoryMock) IsUserExists(uid auth.UserId) (bool, error) {
	return c.IsUserExistsImpl(uid)
}
func (c *RepositoryMock) CheckCredentials(email string, password string) (bool, error) {
	return c.CheckCredentialsImpl(email, password)
}
func (c *RepositoryMock) GetUserIdByEmail(email string) (*auth.UserId, error) {
	return c.GetUserIdByEmailImpl(email)
}
func (c *RepositoryMock) UpdateRefreshToken(uid auth.UserId, token string) repositories.Transaction {
	return c.UpdateRefreshTokenImpl(uid, token)
}
func (c *RepositoryMock) UpdatePassword(uid auth.UserId, newPassword string) repositories.Transaction {
	return c.UpdatePasswordImpl(uid, newPassword)
}
func (c *RepositoryMock) UpdateEmail(uid auth.UserId, newEmail string) repositories.Transaction {
	return c.UpdateEmailImpl(uid, newEmail)
}
func (c *RepositoryMock) GetUserInfo(uid auth.UserId) (auth.UserInfo, error) {
	return c.GetUserInfoImpl(uid)
}
