package openapiImplementation

import (
	"context"
	"errors"
	"fmt"
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) Signup(
	ctx context.Context,
	device string,
	request openapi.SignupRequest,
) (openapi.ImplResponse, error) {

	startupData, err := s.auth.Signup(
		auth.DeviceId(device),
		request.Credentials.Email,
		auth.Password(request.Credentials.Password),
	)
	if err != nil {
		return s.handleSignupError(err, request)
	}

	return openapi.Response(200, openapi.SignupSucceededResponse{
		Response: openapi.StartupData{
			Session:    sessionToOpenapi(startupData.Session),
			Operations: startupData.Operations,
		},
	}), nil
}

func (s *DefaultAPIService) handleSignupError(err error, request openapi.SignupRequest) (openapi.ImplResponse, error) {
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
		s.logger.LogError("signup request %v failed with unknown err: %v", request, err)
		reason = openapi.INTERNAL
		statusCode = 500
	}

	description := fmt.Errorf("signup error: %w", err).Error()
	return openapi.Response(statusCode, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      reason,
			Description: &description,
		},
	}), nil
}
