package defaultJwtService

import (
	"errors"
	"fmt"
	jwtService "verni/internal/services/jwt"

	"github.com/golang-jwt/jwt/v5"
)

func (c *defaultService) ValidateToken(token string, tokenSecret string, tokenType string) (Claims, error) {
	op := fmt.Sprintf("jwt.defaultService.validateToken.%s", tokenType)

	rawToken, err := GetToken(token, []byte(tokenSecret))
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			return Claims{}, fmt.Errorf("%s: token expired: %w", op, jwtService.TokenExpired)
		}
		return Claims{}, fmt.Errorf("%s: invalid token: %w", op, jwtService.BadToken)
	}

	if rawToken == nil {
		return Claims{}, fmt.Errorf("%s: nil token received: %w", op, jwtService.BadToken)
	}

	claims, ok := rawToken.Claims.(*Claims)
	if !ok {
		return Claims{}, fmt.Errorf("%s: invalid token claims format: %w", op, jwtService.BadToken)
	}

	if claims.TokenType != tokenType {
		return Claims{}, fmt.Errorf("%s: unexpected token type %q: %w", op, claims.TokenType, jwtService.BadToken)
	}

	if claims.ExpiresAt == nil {
		return Claims{}, fmt.Errorf("%s: missing expiration time: %w", op, jwtService.BadToken)
	}

	return *claims, nil
}
