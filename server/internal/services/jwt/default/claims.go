package defaultJwtService

import (
	"fmt"
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

// NewTokenClaims creates a new Claims instance with the given parameters
func NewTokenClaims(
	subject jwtService.Subject,
	now time.Time,
	tokenType string,
	lifetime time.Duration,
) Claims {
	return Claims{
		TokenType: tokenType,
		Device:    subject.Device,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   string(subject.User),
			ExpiresAt: jwt.NewNumericDate(now.Add(lifetime)),
			IssuedAt:  jwt.NewNumericDate(now),
		},
	}
}

// NewTokenString creates a signed JWT string from claims
func NewTokenString(claims Claims, secret []byte) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(secret)
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err)
	}
	return tokenString, nil
}

// GetToken parses and validates a JWT string
func GetToken(signedToken string, secret []byte) (*jwt.Token, error) {
	token, err := jwt.ParseWithClaims(
		signedToken,
		&Claims{},
		func(token *jwt.Token) (interface{}, error) {
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
			}
			return secret, nil
		},
	)
	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}
	return token, nil
}
