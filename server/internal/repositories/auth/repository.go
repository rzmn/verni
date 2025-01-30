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
	CreateUser(user UserId, email string, password string) repositories.Transaction

	MarkUserEmailValidated(user UserId) repositories.Transaction

	IsUserExists(user UserId) (bool, error)

	IsSessionExists(user UserId, device DeviceId) (bool, error)

	ExclusiveSession(user UserId, device DeviceId) repositories.Transaction

	CheckCredentials(email string, password string) (bool, error)

	GetUserIdByEmail(email string) (*UserId, error)

	UpdateRefreshToken(user UserId, device DeviceId, token string) repositories.Transaction

	CheckRefreshToken(user UserId, device DeviceId, token string) (bool, error)

	UpdatePassword(user UserId, newPassword string) repositories.Transaction

	UpdateEmail(user UserId, newEmail string) repositories.Transaction

	GetUserInfo(user UserId) (UserInfo, error)
}
