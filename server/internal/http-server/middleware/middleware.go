package middleware

import (
	"errors"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"

	"accounty/internal/auth/jwt"

	"accounty/internal/http-server/helpers"
	"accounty/internal/http-server/responses"
)

func EnsureLoggedIn() gin.HandlerFunc {
	return func(c *gin.Context) {
		const op = "handlers.friends.ensureLoggedInMiddleware"

		log.Printf("%s: validating access token", op)
		token := helpers.ExtractBearerToken(c)
		if err := jwt.ValidateAccessToken(token); err != nil {
			log.Printf("%s: failed to validate token %v", op, err)
			if errors.Is(err, jwt.ErrTokenExpired) {
				c.AbortWithStatusJSON(http.StatusUnauthorized, responses.Failure(responses.Error{
					Code: responses.CodeTokenExpired,
				}))
			} else if errors.Is(err, jwt.ErrBadToken) {
				c.AbortWithStatusJSON(http.StatusUnprocessableEntity, responses.Failure(responses.Error{
					Code: responses.CodeWrongAccessToken,
				}))
			} else {
				c.AbortWithStatusJSON(http.StatusInternalServerError, responses.Failure(responses.Error{
					Code: responses.CodeInternal,
				}))
			}
		} else {
			log.Printf("%s: access token ok", op)
			c.Next()
		}
	}
}
