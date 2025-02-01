package openapiImplementation

import (
	"context"
	"fmt"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) RegisterForPushNotifications(
	ctx context.Context,
	token string,
	request openapi.RegisterForPushNotificationsRequest,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.auth.RegisterForPushNotifications(
		request.Token,
		sessionInfo.User,
		sessionInfo.Device,
	); err != nil {
		return s.handleRegisterForPushNotificationsError(err, request)
	}

	return openapi.Response(200, openapi.RegisterForPushNotificationsSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

func (s *DefaultAPIService) handleRegisterForPushNotificationsError(
	err error,
	request openapi.RegisterForPushNotificationsRequest,
) (openapi.ImplResponse, error) {
	var reason openapi.ErrorReason
	var statusCode int

	switch {
	default:
		s.logger.LogError("register for push notifications request %v failed with unknown err: %v", request, err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("register for push notifications error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
