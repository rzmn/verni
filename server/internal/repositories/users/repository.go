package users

import (
	"verni/internal/repositories"
)

type UserId string
type ImageId string

type Repository interface {
	CreateUser(user UserId, name string) repositories.Transaction
	UpdateUser(user UserId, name *string, avatar *ImageId) repositories.Transaction
	SearchUsers(query string) ([]UserId, error)
}
