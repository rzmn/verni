package pushNotifications

import (
	"verni/internal/repositories"
)

type UserId string
type DeviceId string

type Repository interface {
	StorePushToken(user UserId, device DeviceId, token string) repositories.UnitOfWork
	GetPushToken(user UserId, device DeviceId) (*string, error)
}
