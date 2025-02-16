package jwt_mock

import (
	"verni/internal/services/jwt"
)

type ServiceMock struct {
	IssueRefreshTokenImpl      func(subject jwt.Subject) (jwt.RefreshToken, error)
	IssueAccessTokenImpl       func(subject jwt.Subject) (jwt.AccessToken, error)
	ValidateRefreshTokenImpl   func(token jwt.RefreshToken) error
	ValidateAccessTokenImpl    func(token jwt.AccessToken) error
	GetRefreshTokenSubjectImpl func(token jwt.RefreshToken) (jwt.Subject, error)
	GetAccessTokenSubjectImpl  func(token jwt.AccessToken) (jwt.Subject, error)
}

func (c *ServiceMock) IssueRefreshToken(subject jwt.Subject) (jwt.RefreshToken, error) {
	return c.IssueRefreshTokenImpl(subject)
}

func (c *ServiceMock) IssueAccessToken(subject jwt.Subject) (jwt.AccessToken, error) {
	return c.IssueAccessTokenImpl(subject)
}

func (c *ServiceMock) ValidateRefreshToken(token jwt.RefreshToken) error {
	return c.ValidateRefreshTokenImpl(token)
}

func (c *ServiceMock) ValidateAccessToken(token jwt.AccessToken) error {
	return c.ValidateAccessTokenImpl(token)
}

func (c *ServiceMock) GetRefreshTokenSubject(token jwt.RefreshToken) (jwt.Subject, error) {
	return c.GetRefreshTokenSubjectImpl(token)
}

func (c *ServiceMock) GetAccessTokenSubject(token jwt.AccessToken) (jwt.Subject, error) {
	return c.GetAccessTokenSubjectImpl(token)
}
