package openapiImplementation

import (
	"context"
	"errors"
	"fmt"
	"verni/internal/controllers/verification"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) ConfirmEmail(
	ctx context.Context,
	token string,
	request openapi.ConfirmEmailRequest,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.verification.ConfirmEmail(
		verification.UserId(sessionInfo.User),
		request.Code,
	); err != nil {
		return s.handleConfirmEmailError(err, request)
	}

	return openapi.Response(200, openapi.ConfirmEmailSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

func (s *DefaultAPIService) handleConfirmEmailError(
	err error,
	request openapi.ConfirmEmailRequest,
) (openapi.ImplResponse, error) {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	case errors.Is(err, verification.WrongConfirmationCode):
		reason = openapi.INCORRECT_CREDENTIALS
		statusCode = 409
	default:
		s.logger.LogError("confirm email request %v failed with unknown err: %v", request, err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("confirm email error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
