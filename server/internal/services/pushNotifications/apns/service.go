package applePushNotifications

import (
	"encoding/json"
	"fmt"
	"os"

	pushNotificationsRepository "verni/internal/repositories/pushNotifications"
	"verni/internal/services/logging"
	"verni/internal/services/pathProvider"
	"verni/internal/services/pushNotifications"

	"github.com/sideshow/apns2"
	"github.com/sideshow/apns2/certificate"
)

type ApnsConfig struct {
	CertificatePath string `json:"certificatePath"`
	CredentialsPath string `json:"credentialsPath"`
	BundleId        string `json:"bundleId"`
}

type Repository pushNotificationsRepository.Repository

func New(
	config ApnsConfig,
	logger logging.Service,
	pathProviderService pathProvider.Service,
) (pushNotifications.Service, error) {
	const op = "apns.AppleService"
	credentialsData, err := os.ReadFile(pathProviderService.AbsolutePath(config.CredentialsPath))
	if err != nil {
		return &appleService{}, fmt.Errorf("%s: opening config: %w", op, err)
	}
	var credentials ApnsCredentials
	json.Unmarshal(credentialsData, &credentials)
	cert, err := certificate.FromP12File(pathProviderService.AbsolutePath(config.CertificatePath), credentials.Password)
	if err != nil {
		return &appleService{}, fmt.Errorf("%s: opening p12 creds %w", op, err)
	}
	return &appleService{
		client:   apns2.NewClient(cert).Production(),
		bundleId: config.BundleId,
		logger:   logger,
	}, nil
}

type appleService struct {
	client   *apns2.Client
	bundleId string
	logger   logging.Service
}

type Push struct {
	Aps  PushPayload `json:"aps"`
	Data interface{} `json:"d"`
}

type PushPayload struct {
	MutableContent *int             `json:"mutable-content,omitempty"`
	Alert          PushPayloadAlert `json:"alert"`
}

type PushPayloadAlert struct {
	Title    string  `json:"title"`
	Subtitle *string `json:"subtitle,omitempty"`
	Body     *string `json:"body,omitempty"`
}

type ApnsCredentials struct {
	Password string `json:"cert_pwd"`
}

func (c *appleService) Alert(token pushNotifications.Token, title string, subtitle *string, body *string, data interface{}) error {
	const op = "apns.defaultService.send"
	c.logger.LogInfo("%s: start[token=%s title=%s subtitle=%s body=%s data=%v]", op, token, title, subtitle, body, data)

	notification := &apns2.Notification{}
	notification.DeviceToken = string(token)
	notification.Topic = c.bundleId
	mutable := 1
	payloadString, err := json.Marshal(Push{
		Aps: PushPayload{
			MutableContent: &mutable,
			Alert: PushPayloadAlert{
				Title:    title,
				Subtitle: subtitle,
				Body:     body,
			},
		},
		Data: data,
	})
	if err != nil {
		return fmt.Errorf("%s: making payload string: %w", op, err)
	}

	notification.Payload = payloadString
	res, err := c.client.Push(notification)
	if err != nil {
		return fmt.Errorf("%s: sending notification: %w", op, err)
	}

	c.logger.LogInfo("%s: success[token=%s result=%v payload=%s]", op, token, res, payloadString)
	return nil
}
