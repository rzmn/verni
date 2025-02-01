package openapiImplementation

import (
	"errors"
	"fmt"
	"strings"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) validateToken(rawTokenValue string) (auth.UserDevice, *openapi.ImplResponse) {
	splitted := strings.Fields(rawTokenValue)
	if len(splitted) != 2 {
		description := "wrong token format"
		return auth.UserDevice{}, s.createCheckAuthHeaderResponse(401, openapi.BAD_REQUEST, description)
	}

	// Check the token
	session, err := s.auth.CheckToken(splitted[1])
	if err != nil {
		return auth.UserDevice{}, s.handleTokenError(err)
	}

	return session, nil
}

func (s *DefaultAPIService) createCheckAuthHeaderResponse(statusCode int, reason openapi.ErrorReason, description string) *openapi.ImplResponse {
	response := openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	})
	return &response
}

func (s *DefaultAPIService) handleTokenError(err error) *openapi.ImplResponse {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	case errors.Is(err, auth.TokenExpired):
		reason = openapi.TOKEN_EXPIRED
		statusCode = 401
	case errors.Is(err, auth.BadFormat):
		reason = openapi.BAD_REQUEST
	default:
		s.logger.LogError("check auth header failed with unknown err: %v", err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("check auth header error: %w", err).Error()
	return s.createCheckAuthHeaderResponse(statusCode, reason, description)
}
