package auth

import (
	"errors"
)

type UserId string
type DeviceId string
type Password string

type Session struct {
	Id           UserId
	AccessToken  string
	RefreshToken string
}

var (
	WrongCredentials = errors.New("wrong credentials")
	AlreadyTaken     = errors.New("already taken")
	NotDelivered     = errors.New("not delivered")
	TokenExpired     = errors.New("token expired")
	BadFormat        = errors.New("bad format")
	NoSuchUser       = errors.New("no such user")
)

type Controller interface {
	Signup(device DeviceId, email string, password Password) (Session, error)

	Login(device DeviceId, email string, password Password) (Session, error)

	Refresh(refreshToken string) (Session, error)

	CheckToken(accessToken string) (UserId, error)

	Logout(user UserId) error

	UpdateEmail(email string, user UserId) (Session, error)

	UpdatePassword(old Password, new Password, user UserId) (Session, error)

	RegisterForPushNotifications(token string, user UserId) error
}
