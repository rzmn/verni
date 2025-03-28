package pushNotifications_mock

import (
	"verni/internal/repositories"
	"verni/internal/repositories/pushNotifications"
)

type RepositoryMock struct {
	StorePushTokenImpl func(uid pushNotifications.UserId, device pushNotifications.DeviceId, token string) repositories.UnitOfWork
	GetPushTokenImpl   func(uid pushNotifications.UserId, device pushNotifications.DeviceId) (*string, error)
	GetPushTokensImpl  func(sessions []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error)
}

func (c *RepositoryMock) StorePushToken(uid pushNotifications.UserId, device pushNotifications.DeviceId, token string) repositories.UnitOfWork {
	return c.StorePushTokenImpl(uid, device, token)
}

func (c *RepositoryMock) GetPushToken(uid pushNotifications.UserId, device pushNotifications.DeviceId) (*string, error) {
	return c.GetPushTokenImpl(uid, device)
}

func (c *RepositoryMock) GetPushTokens(sessions []pushNotifications.UserId) (map[pushNotifications.UserId][]string, error) {
	return c.GetPushTokensImpl(sessions)
}
