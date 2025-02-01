package openapiImplementation

import (
	"verni/internal/controllers/auth"
	openapi "verni/internal/openapi/go"
)

func sessionToOpenapi(session auth.Session) openapi.Session {
	return openapi.Session{
		Id:           string(session.Id),
		AccessToken:  string(session.AccessToken),
		RefreshToken: string(session.RefreshToken),
	}
}
