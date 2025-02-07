package openapiImplementation

import (
	"context"
	"fmt"
	"verni/internal/controllers/operations"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) PullOperations(
	ctx context.Context,
	token string,
	operationsType openapi.OperationType,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	result, err := s.operations.Pull(
		operations.UserId(sessionInfo.User),
		operations.DeviceId(sessionInfo.Device),
		operationsType,
	)
	if err != nil {
		return s.handlePullOperationsError(err)
	}

	return openapi.Response(200, openapi.PullOperationsSucceededResponse{
		Response: result,
	}), nil
}

func (s *DefaultAPIService) handlePullOperationsError(err error) (openapi.ImplResponse, error) {
	s.logger.LogError("pull operations failed: %v", err)

	description := fmt.Errorf("pull operations error: %w", err).Error()
	return openapi.Response(500, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      openapi.INTERNAL,
			Description: &description,
		},
	}), nil
}
