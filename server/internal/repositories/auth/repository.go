package auth

import (
	"verni/internal/repositories"
)

type UserId string
type DeviceId string
type UserInfo struct {
	UserId        UserId
	Email         string
	PasswordHash  string
	EmailVerified bool
}

type Repository interface {
	CreateUser(user UserId, email string, password string) repositories.UnitOfWork

	MarkUserEmailValidated(user UserId) repositories.UnitOfWork

	IsUserExists(user UserId) (bool, error)

	IsSessionExists(user UserId, device DeviceId) (bool, error)

	ExclusiveSession(user UserId, device DeviceId) repositories.UnitOfWork

	CheckCredentials(email string, password string) (bool, error)

	GetUserIdByEmail(email string) (*UserId, error)

	UpdateRefreshToken(user UserId, device DeviceId, token string) repositories.UnitOfWork

	CheckRefreshToken(user UserId, device DeviceId, token string) (bool, error)

	UpdatePassword(user UserId, newPassword string) repositories.UnitOfWork

	UpdateEmail(user UserId, newEmail string) repositories.UnitOfWork

	GetUserInfo(user UserId) (UserInfo, error)
}
