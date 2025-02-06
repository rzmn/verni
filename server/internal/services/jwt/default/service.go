package defaultJwtService

import (
	"fmt"
	"time"

	jwtService "verni/internal/services/jwt"
	"verni/internal/services/logging"
)

type DefaultConfig struct {
	AccessTokenLifetimeHours  int    `json:"accessTokenLifetimeHours"`
	RefreshTokenLifetimeHours int    `json:"refreshTokenLifetimeHours"`
	RefreshTokenSecret        string `json:"refreshTokenSecret"`
	AccessTokenSecret         string `json:"accessTokenSecret"`
}

func New(
	config DefaultConfig,
	logger logging.Service,
	currentTime func() time.Time,
) jwtService.Service {
	return &defaultService{
		refreshTokenLifetime: time.Hour * time.Duration(config.RefreshTokenLifetimeHours),
		accessTokenLifetime:  time.Hour * time.Duration(config.AccessTokenLifetimeHours),
		refreshTokenSecret:   config.RefreshTokenSecret,
		accessTokenSecret:    config.AccessTokenSecret,
		currentTime:          currentTime,
		logger:               logger,
	}
}

type defaultService struct {
	refreshTokenLifetime time.Duration
	accessTokenLifetime  time.Duration
	refreshTokenSecret   string
	accessTokenSecret    string
	currentTime          func() time.Time
	logger               logging.Service
}

func (c *defaultService) IssueRefreshToken(subject jwtService.Subject) (jwtService.RefreshToken, error) {
	claims := NewTokenClaims(
		subject,
		c.currentTime(),
		TokenTypeRefresh,
		c.refreshTokenLifetime,
	)

	token, err := NewTokenString(claims, []byte(c.refreshTokenSecret))
	if err != nil {
		return "", fmt.Errorf("issuing refresh token for subject %v: %w", subject, err)
	}
	return jwtService.RefreshToken(token), nil
}

func (c *defaultService) IssueAccessToken(subject jwtService.Subject) (jwtService.AccessToken, error) {
	claims := NewTokenClaims(
		subject,
		c.currentTime(),
		TokenTypeAccess,
		c.accessTokenLifetime,
	)

	token, err := NewTokenString(claims, []byte(c.accessTokenSecret))
	if err != nil {
		return "", fmt.Errorf("issuing access token for %v: %w", subject, err)
	}
	return jwtService.AccessToken(token), nil
}

func (c *defaultService) ValidateRefreshToken(token jwtService.RefreshToken) error {
	_, err := c.ValidateToken(string(token), c.refreshTokenSecret, TokenTypeRefresh)
	return err
}

func (c *defaultService) ValidateAccessToken(token jwtService.AccessToken) error {
	_, err := c.ValidateToken(string(token), c.accessTokenSecret, TokenTypeAccess)
	return err
}

func (c *defaultService) GetRefreshTokenSubject(token jwtService.RefreshToken) (jwtService.Subject, error) {
	claims, err := c.ValidateToken(string(token), c.refreshTokenSecret, TokenTypeRefresh)
	if err != nil {
		return jwtService.Subject{}, fmt.Errorf("getting refresh token subject: %w", err)
	}

	return jwtService.Subject{
		User:   jwtService.UserId(claims.Subject),
		Device: claims.Device,
	}, nil
}

func (c *defaultService) GetAccessTokenSubject(token jwtService.AccessToken) (jwtService.Subject, error) {
	claims, err := c.ValidateToken(string(token), c.accessTokenSecret, TokenTypeAccess)
	if err != nil {
		return jwtService.Subject{}, fmt.Errorf("getting access token subject: %w", err)
	}

	return jwtService.Subject{
		User:   jwtService.UserId(claims.Subject),
		Device: claims.Device,
	}, nil
}
