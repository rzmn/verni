package auth

import (
	"errors"
	openapi "verni/internal/openapi/go"
)

type UserId string
type DeviceId string
type Password string

type Session struct {
	Id           UserId
	AccessToken  string
	RefreshToken string
}

type StartupData struct {
	Session    Session
	Operations []openapi.SomeOperation
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
	Signup(device DeviceId, email string, password Password) (StartupData, error)

	Login(device DeviceId, email string, password Password) (StartupData, error)

	Refresh(refreshToken string) (Session, error)

	CheckToken(accessToken string) (UserDevice, error)

	UpdateEmail(email string, user UserId, device DeviceId) error

	UpdatePassword(old Password, new Password, user UserId, device DeviceId) error

	RegisterForPushNotifications(token string, user UserId, device DeviceId) error
}
