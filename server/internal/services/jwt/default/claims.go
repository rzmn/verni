package defaultJwtService

import (
	"time"
	jwtService "verni/internal/services/jwt"

	"github.com/golang-jwt/jwt/v5"
)

const (
	TokenTypeRefresh = "refresh"
	TokenTypeAccess  = "access"
)

type Claims struct {
	TokenType string              `json:"token"`
	Device    jwtService.DeviceId `json:"device"`
	jwt.RegisteredClaims
}

func NewTokenClaims(
	subject jwtService.Subject,
	timeProvider func() time.Time,
	tokenType string,
	lifetime time.Duration,
) Claims {
	currentTime := timeProvider()
	return Claims{
		TokenType: tokenType,
		Device:    subject.Device,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   string(subject.User),
			ExpiresAt: jwt.NewNumericDate(currentTime.Add(lifetime)),
			IssuedAt:  jwt.NewNumericDate(currentTime),
		},
	}
}

func NewTokenString(claims Claims, secret []byte) (string, error) {
	tokenString, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(secret)
	if err != nil {
		return "", err
	}
	return tokenString, nil
}

func GetToken(signedToken string, secret []byte) (*jwt.Token, error) {
	return jwt.ParseWithClaims(
		signedToken,
		&Claims{},
		func(token *jwt.Token) (interface{}, error) {
			return []byte(secret), nil
		},
	)
}
