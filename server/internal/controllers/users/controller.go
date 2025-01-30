package users

import openapi "verni/internal/openapi/go"

type Controller interface {
	Search(query string) ([]openapi.SomeOperation, error)
}
