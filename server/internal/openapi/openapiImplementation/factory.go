package openapiImplementation

import (
	"verni/internal/controllers/auth"
	"verni/internal/controllers/avatars"
	"verni/internal/controllers/profile"
	"verni/internal/controllers/spendings"
	"verni/internal/controllers/users"
	"verni/internal/controllers/verification"
	openapi "verni/internal/openapi/go"
	"verni/internal/services/logging"
)

func New(
	auth auth.Controller,
	spendings spendings.Controller,
	profile profile.Controller,
	verification verification.Controller,
	users users.Controller,
	avatars avatars.Controller,
	logger logging.Service,
) openapi.DefaultAPIServicer {
	return &DefaultAPIService{
		Auth:         auth,
		Spendings:    spendings,
		Profile:      profile,
		Verification: verification,
		Users:        users,
		Avatars:      avatars,
		logger:       logger,
	}
}
