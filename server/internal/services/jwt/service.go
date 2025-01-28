package jwt

import "errors"

type UserId string
type DeviceId string
type AccessToken string
type RefreshToken string

var (
	BadToken     = errors.New("bad token")
	TokenExpired = errors.New("token expired")
)

type Subject struct {
	User   UserId
	Device DeviceId
}

type Service interface {
	IssueRefreshToken(subject Subject) (RefreshToken, error)
	IssueAccessToken(subject Subject) (AccessToken, error)

	ValidateRefreshToken(token RefreshToken) error
	ValidateAccessToken(token AccessToken) error

	GetRefreshTokenSubject(token RefreshToken) (Subject, error)
	GetAccessTokenSubject(token AccessToken) (Subject, error)
}
