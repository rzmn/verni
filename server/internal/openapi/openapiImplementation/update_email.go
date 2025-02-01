package openapiImplementation

import (
	"context"
	"errors"
	"fmt"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) UpdateEmail(
	ctx context.Context,
	token string,
	request openapi.UpdateEmailRequest,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.auth.UpdateEmail(
		request.Email,
		sessionInfo.User,
		sessionInfo.Device,
	); err != nil {
		return s.handleUpdateEmailError(err, request)
	}

	return openapi.Response(200, openapi.UpdateEmailSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

func (s *DefaultAPIService) handleUpdateEmailError(err error, request openapi.UpdateEmailRequest) (openapi.ImplResponse, error) {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	case errors.Is(err, auth.AlreadyTaken):
		reason = openapi.ALREADY_TAKEN
		statusCode = 409
	case errors.Is(err, auth.BadFormat):
		reason = openapi.WRONG_FORMAT
		statusCode = 422
	default:
		s.logger.LogError("update email request %v failed with unknown err: %v", request, err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("update email error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
