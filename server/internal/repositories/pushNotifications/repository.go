package pushNotifications

import (
	"verni/internal/repositories"
)

type UserId string

type Repository interface {
	StorePushToken(uid UserId, token string) repositories.Transaction
	GetPushToken(uid UserId) (*string, error)
}
