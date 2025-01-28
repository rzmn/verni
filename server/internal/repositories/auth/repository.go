package auth

import (
	"verni/internal/repositories"
)

type UserId string
type UserInfo struct {
	UserId        UserId
	Email         string
	PasswordHash  string
	RefreshToken  string
	EmailVerified bool
}

type Repository interface {
	CreateUser(user UserId, email string, password string, refreshToken string) repositories.Transaction

	MarkUserEmailValidated(user UserId) repositories.Transaction

	IsUserExists(user UserId) (bool, error)

	CheckCredentials(email string, password string) (bool, error)

	GetUserIdByEmail(email string) (*UserId, error)

	UpdateRefreshToken(user UserId, token string) repositories.Transaction

	UpdatePassword(user UserId, newPassword string) repositories.Transaction

	UpdateEmail(user UserId, newEmail string) repositories.Transaction

	GetUserInfo(user UserId) (UserInfo, error)
}
