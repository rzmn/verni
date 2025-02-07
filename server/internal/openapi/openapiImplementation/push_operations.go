package openapiImplementation

import (
	"context"
	"fmt"
	"verni/internal/controllers/operations"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) PushOperations(
	ctx context.Context,
	token string,
	request openapi.PushOperationsRequest,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.operations.Push(
		request.Operations,
		operations.UserId(sessionInfo.User),
		operations.DeviceId(sessionInfo.Device),
	); err != nil {
		return s.handlePushOperationsError(err, request)
	}

	return openapi.Response(200, openapi.PushOperationsSucceededResponse{
		Response: request.Operations,
	}), nil
}

func (s *DefaultAPIService) handlePushOperationsError(err error, request openapi.PushOperationsRequest) (openapi.ImplResponse, error) {
	s.logger.LogError("push operations %v failed: %v", request, err)

	description := fmt.Errorf("pull operations error: %w", err).Error()
	return openapi.Response(500, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      openapi.INTERNAL,
			Description: &description,
		},
	}), nil
}
