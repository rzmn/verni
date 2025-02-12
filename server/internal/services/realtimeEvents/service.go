package realtimeEvents

type UserId string
type DeviceId string

type Listener func(userId UserId, ignoringDevices []DeviceId)

type Service interface {
	AddListener(listener Listener)
	NotifyUpdate(userId UserId, ignoringDevices []DeviceId)
}
