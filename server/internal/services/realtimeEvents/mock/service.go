package realtimeEvents_mock

import "verni/internal/services/realtimeEvents"

type ServiceMock struct {
	AddListenerImpl  func(listener realtimeEvents.Listener)
	NotifyUpdateImpl func(userId realtimeEvents.UserId, ignoringDevices []realtimeEvents.DeviceId)
}

func (c *ServiceMock) AddListener(listener realtimeEvents.Listener) {
	c.AddListenerImpl(listener)
}

func (c *ServiceMock) NotifyUpdate(userId realtimeEvents.UserId, ignoringDevices []realtimeEvents.DeviceId) {
	c.NotifyUpdateImpl(userId, ignoringDevices)
}
