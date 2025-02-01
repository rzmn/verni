package openapiImplementation

import (
	"context"
	"fmt"
	"verni/internal/common"
	"verni/internal/controllers/images"
	openapi "verni/internal/openapi/go"
)

func (s *DefaultAPIService) GetAvatars(
	ctx context.Context,
	token string,
	ids []string,
) (openapi.ImplResponse, error) {
	if _, earlyResponse := s.validateToken(token); earlyResponse != nil {
		return *earlyResponse, nil
	}

	imageIDs := common.Map(ids, func(id string) images.ImageId {
		return images.ImageId(id)
	})

	result, err := s.images.GetImages(imageIDs)
	if err != nil {
		return s.handleGetAvatarsError(err, ids)
	}

	response := make(map[string]openapi.Image, len(result))
	for _, avatar := range result {
		response[string(avatar.Id)] = openapi.Image{
			Id:     string(avatar.Id),
			Base64: avatar.Base64,
		}
	}

	return openapi.Response(200, openapi.GetAvatarsSucceededResponse{
		Response: response,
	}), nil
}

func (s *DefaultAPIService) handleGetAvatarsError(err error, request []string) (openapi.ImplResponse, error) {
	s.logger.LogError("get avatars request %v failed: %v", request, err)

	description := fmt.Errorf("get avatars error: %w", err).Error()
	return openapi.Response(500, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason:      openapi.INTERNAL,
			Description: &description,
		},
	}), nil
}
