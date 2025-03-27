package pushNotifications_mock

import "verni/internal/services/pushNotifications"

type ServiceMock struct {
}

func New() pushNotifications.Service {
	return &ServiceMock{}
}

func (s *ServiceMock) Alert(token pushNotifications.Token, title string, subtitle *string, body *string, data interface{}) error {
	return nil
}
