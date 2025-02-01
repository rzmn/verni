package openapiImplementation

import (
	"verni/internal/controllers/auth"
	"verni/internal/controllers/images"
	"verni/internal/controllers/operations"
	"verni/internal/controllers/users"
	"verni/internal/controllers/verification"
	openapi "verni/internal/openapi/go"
	"verni/internal/services/logging"
)

func New(
	auth auth.Controller,
	verification verification.Controller,
	users users.Controller,
	images images.Controller,
	operations operations.Controller,
	logger logging.Service,
) openapi.DefaultAPIServicer {
	return &DefaultAPIService{
		auth:         auth,
		verification: verification,
		users:        users,
		images:       images,
		operations:   operations,
		logger:       logger,
	}
}

// DefaultAPIService is a service that implements the logic for the DefaultAPIServicer
// This service should implement the business logic for every endpoint for the DefaultAPI API.
// Include any external packages or services that will be required by this service.
type DefaultAPIService struct {
	auth         auth.Controller
	verification verification.Controller
	users        users.Controller
	images       images.Controller
	operations   operations.Controller
	logger       logging.Service
}
