package apns

import (
	"encoding/json"
	"fmt"
	"log"
	"os"

	"github.com/sideshow/apns2"
	"github.com/sideshow/apns2/certificate"
)

type PushNotificationSender struct {
	client *apns2.Client
}

type Push struct {
	Aps PushPayload `json:"aps"`
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

type Config struct {
	Password string `json:"cert_pwd"`
}

func (s *PushNotificationSender) GotFriendRequest(token string, sender string) {
	body := fmt.Sprintf("From: %s", sender)
	s.send(token, Push{
		Aps: PushPayload{
			MutableContent: nil,
			Alert: PushPayloadAlert{
				Title:    "Got Friend Request",
				Subtitle: nil,
				Body:     &body,
			},
		},
	})
}

func (s *PushNotificationSender) send(token string, payload Push) error {
	const op = "apns.PushNotificationSender.Send"
	notification := &apns2.Notification{}
	notification.DeviceToken = token
	notification.Topic = "com.rzmn.accountydev.app"

	payloadString, err := json.Marshal(payload)
	if err != nil {
		log.Printf("%s: failed create payload string: %v", op, err)
		return err
	}
	log.Printf("%s: sending push: %s", op, payloadString)
	notification.Payload = payloadString

	res, err := s.client.Push(notification)

	if err != nil {
		log.Printf("%s: failed to send notification: %v", op, err)
		return err
	}
	fmt.Printf("%s: sent %v %v %v\n", op, res.StatusCode, res.ApnsID, res.Reason)
	return nil
}

func New(certPath string, configPath string) (PushNotificationSender, error) {
	const op = "apns.PushNotificationSender.New"
	byteValue, err := os.ReadFile(configPath)
	if err != nil {
		log.Printf("%s: failed to open config: %v", op, err)
		return PushNotificationSender{}, err
	}
	var config Config
	json.Unmarshal(byteValue, &config)
	cert, err := certificate.FromP12File(certPath, config.Password)
	if err != nil {
		log.Printf("%s: failed to open p12: %v", op, err)
		return PushNotificationSender{}, err
	}
	return PushNotificationSender{
		client: apns2.NewClient(cert).Production(),
	}, nil
}
