package openapiImplementation

import (
	"context"
	"fmt"
	"verni/internal/controllers/verification"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) SendEmailConfirmationCode(
	ctx context.Context,
	token string,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.verification.SendConfirmationCode(
		verification.UserId(sessionInfo.User),
	); err != nil {
		return s.handleSendConfirmationCodeError(err)
	}

	return openapi.Response(200, openapi.RegisterForPushNotificationsSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

func (s *DefaultAPIService) handleSendConfirmationCodeError(err error) (openapi.ImplResponse, error) {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	default:
		s.logger.LogError("send email confirmation code failed with unknown err: %v", err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("send email confirmation code error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
