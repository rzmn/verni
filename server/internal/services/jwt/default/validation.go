package defaultJwtService

import (
	"errors"
	"fmt"
	jwtService "verni/internal/services/jwt"

	"github.com/golang-jwt/jwt/v5"
)

func (c *defaultService) ValidateToken(token string, tokenSecret string, tokenType string) (Claims, error) {
	op := fmt.Sprintf("jwt.defaultService.validateToken.%s", tokenType)
	rawToken, err := GetToken(string(token), []byte(tokenSecret))
	if err != nil {
		c.logger.LogInfo("%s: jwt error: %v", op, err)
		if errors.Is(err, jwt.ErrTokenExpired) {
			return Claims{}, fmt.Errorf("getting token from string %s: %w", token, jwtService.TokenExpired)
		} else {
			return Claims{}, fmt.Errorf("getting token from string %s: %w", token, jwtService.BadToken)
		}
	}
	if rawToken == nil {
		c.logger.LogInfo("%s found nil token", op)
		return Claims{}, fmt.Errorf("getting token from string %s - empty token: %w", token, jwtService.BadToken)
	}
	claims, ok := rawToken.Claims.(*Claims)
	if !ok {
		c.logger.LogInfo("%s invalid token claims, token: %s", op, token)
		return Claims{}, fmt.Errorf("getting token claims %s: %w", token, jwtService.BadToken)
	}
	if claims.TokenType != tokenType {
		c.logger.LogInfo("%s: wrong token type %s", op, claims.TokenType)
		return Claims{}, fmt.Errorf("checking token type %s: %w", token, jwtService.BadToken)
	}
	if claims.ExpiresAt == nil {
		c.logger.LogInfo("%s: missing token expiration time %s", op, claims.TokenType)
		return Claims{}, fmt.Errorf("checking token type %s: %w", token, jwtService.BadToken)
	}
	return *claims, nil
}
