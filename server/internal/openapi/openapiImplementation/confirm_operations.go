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
	request openapi.ConfirmOperationsRequest,
) (openapi.ImplResponse, error) {
	sessionInfo, earlyResponse := s.validateToken(token)
	if earlyResponse != nil {
		return *earlyResponse, nil
	}

	if err := s.operations.Confirm(
		common.Map(request.Ids, func(id string) operations.OperationId {
			return operations.OperationId(id)
		}),
		operations.UserId(sessionInfo.User),
		operations.DeviceId(sessionInfo.Device),
	); err != nil {
		return s.handleConfirmOperationsError(err, request.Ids)
	}

	return openapi.Response(200, openapi.ConfirmOperationsSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

func (s *DefaultAPIService) handleConfirmOperationsError(err error, ids []string) (openapi.ImplResponse, error) {
	s.logger.LogError("confirm operations %v failed: %v", ids, err)

	description := fmt.Errorf("confirm operations error: %w", err).Error()
	return openapi.Response(500, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      openapi.INTERNAL,
			Description: &description,
		},
	}), nil
}
