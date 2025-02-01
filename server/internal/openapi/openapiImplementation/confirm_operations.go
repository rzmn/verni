package openapiImplementation

import (
	"context"
	"fmt"
	"verni/internal/common"
	"verni/internal/controllers/operations"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) ConfirmOperations(
	ctx context.Context,
	token string,
	ids []string,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.operations.Confirm(
		common.Map(ids, func(id string) operations.OperationId {
			return operations.OperationId(id)
		}),
		operations.UserId(sessionInfo.User),
		operations.DeviceId(sessionInfo.Device),
	); err != nil {
		return s.handleConfirmOperationsError(err, ids)
	}

	return openapi.Response(200, openapi.PushOperationsSucceededResponse{
		Response: []openapi.SomeOperation{},
	}), nil
}

func (s *DefaultAPIService) handleConfirmOperationsError(err error, ids []string) (openapi.ImplResponse, error) {
	s.logger.LogError("push operations %v failed: %v", ids, err)

	description := fmt.Errorf("pull operations error: %w", err).Error()
	return openapi.Response(500, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      openapi.INTERNAL,
			Description: &description,
		},
	}), nil
}
