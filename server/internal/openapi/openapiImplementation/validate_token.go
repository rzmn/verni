package openapiImplementation

import (
	"errors"
	"fmt"
	"strings"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
	"verni/internal/services/logging"
)

func (s *DefaultAPIService) validateToken(rawTokenValue string) (auth.UserDevice, *openapi.ImplResponse) {
	return validateToken(s.logger, s.auth, rawTokenValue)
}

func validateToken(logger logging.Service, authController auth.Controller, rawTokenValue string) (auth.UserDevice, *openapi.ImplResponse) {
	splitted := strings.Fields(rawTokenValue)
	if len(splitted) != 2 {
		description := "wrong token format"
		return auth.UserDevice{}, createCheckAuthHeaderResponse(401, openapi.BAD_REQUEST, description)
	}

	// Check the token
	session, err := authController.CheckToken(splitted[1])
	if err != nil {
		return auth.UserDevice{}, handleTokenError(logger, err)
	}

	return session, nil
}

func createCheckAuthHeaderResponse(statusCode int, reason openapi.ErrorReason, description string) *openapi.ImplResponse {
	response := openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	})
	return &response
}

func handleTokenError(logger logging.Service, err error) *openapi.ImplResponse {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	case errors.Is(err, auth.TokenExpired):
		reason = openapi.TOKEN_EXPIRED
		statusCode = 401
	case errors.Is(err, auth.BadFormat):
		reason = openapi.BAD_REQUEST
		statusCode = 400
	default:
		logger.LogError("check auth header failed with unknown err: %v", err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("check auth header error: %w", err).Error()
	return createCheckAuthHeaderResponse(statusCode, reason, description)
}
