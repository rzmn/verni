package openapiImplementation

import (
	"context"
	"errors"
	"fmt"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) RefreshSession(
	ctx context.Context,
	request openapi.RefreshSessionRequest,
) (openapi.ImplResponse, error) {

	session, err := s.auth.Refresh(
		request.RefreshToken,
	)
	if err != nil {
		return s.handleRefreshError(err, request)
	}

	return openapi.Response(200, openapi.RefreshSucceededResponse{
		Response: sessionToOpenapi(session),
	}), nil
}

func (s *DefaultAPIService) handleRefreshError(err error, request openapi.RefreshSessionRequest) (openapi.ImplResponse, error) {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	case errors.Is(err, auth.TokenExpired):
		reason = openapi.TOKEN_EXPIRED
		statusCode = 401
	case errors.Is(err, auth.BadFormat), errors.Is(err, auth.WrongCredentials):
		reason = openapi.WRONG_ACCESS_TOKEN
		statusCode = 409
	default:
		s.logger.LogError("refresh request %v failed with unknown err: %v", request, err)
		reason = openapi.INTERNAL
		statusCode = 500
	}
	description := fmt.Errorf("refresh error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
