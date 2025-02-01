package openapiImplementation

import (
	"context"
	"errors"
	"fmt"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) UpdatePassword(
	ctx context.Context,
	token string,
	request openapi.UpdatePasswordRequest,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.auth.UpdatePassword(
		auth.Password(request.Old),
		auth.Password(request.New),
		sessionInfo.User,
		sessionInfo.Device,
	); err != nil {
		return s.handleUpdatePasswordError(err, request)
	}

	return openapi.Response(200, openapi.UpdatePasswordSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

func (s *DefaultAPIService) handleUpdatePasswordError(err error, request openapi.UpdatePasswordRequest) (openapi.ImplResponse, error) {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	case errors.Is(err, auth.WrongCredentials):
		reason = openapi.INCORRECT_CREDENTIALS
		statusCode = 409
	case errors.Is(err, auth.BadFormat):
		reason = openapi.WRONG_FORMAT
		statusCode = 422
	default:
		s.logger.LogError("update password request %v failed with unknown err: %v", request, err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("update password error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
