package openapiImplementation

import (
	"context"
	"fmt"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) SearchUsers(
	ctx context.Context,
	token string,
	searchQuery string,
) (openapi.ImplResponse, error) {
	if _, earlyResponse := s.validateToken(token); earlyResponse != nil {
		return *earlyResponse, nil
	}

	result, err := s.users.Search(searchQuery)
	if err != nil {
		return s.handleSearchUsersError(err, searchQuery)
	}

	return openapi.Response(200, openapi.SearchUsersSucceededResponse{
		Response: result,
	}), nil
}

func (s *DefaultAPIService) handleSearchUsersError(err error, searchQuery string) (openapi.ImplResponse, error) {
	s.logger.LogError("search users %s failed: %v", searchQuery, err)

	description := fmt.Errorf("search users error: %w", err).Error()
	return openapi.Response(500, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      openapi.INTERNAL,
			Description: &description,
		},
	}), nil
}
