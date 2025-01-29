package verification

import (
	"errors"
)

type UserId string

var (
	CodeHasNotBeenSent    = errors.New("code has not been sent")
	CodeNotDelivered      = errors.New("not delivered")
	WrongConfirmationCode = errors.New("wrong confirmation code")
)

type Controller interface {
	SendConfirmationCode(uid UserId) error
	ConfirmEmail(uid UserId, code string) error
}
