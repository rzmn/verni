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

type UserDevice struct {
	User   UserId
	Device DeviceId
}

var (
	WrongCredentials = errors.New("wrong credentials")
	AlreadyTaken     = errors.New("already taken")
	NotDelivered     = errors.New("not delivered")
	TokenExpired     = errors.New("token expired")
	BadFormat        = errors.New("bad format")
	NoSuchEntity     = errors.New("no such entity")
)

type Controller interface {
	Signup(device DeviceId, email string, password Password) (Session, error)

	Login(device DeviceId, email string, password Password) (Session, error)

	Refresh(refreshToken string) (Session, error)

	CheckToken(accessToken string) (UserDevice, error)

	UpdateEmail(email string, user UserId, device DeviceId) error

	UpdatePassword(old Password, new Password, user UserId, device DeviceId) error

	RegisterForPushNotifications(token string, user UserId, device DeviceId) error
}
