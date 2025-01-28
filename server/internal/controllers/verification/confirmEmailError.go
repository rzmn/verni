package verification

type ConfirmEmailErrorCode int

const (
	_ ConfirmEmailErrorCode = iota
	ConfirmEmailErrorCodeHasNotBeenSent
	ConfirmEmailErrorWrongConfirmationCode
	ConfirmEmailErrorInternal
)

func (c ConfirmEmailErrorCode) Message() string {
	switch c {
	case ConfirmEmailErrorWrongConfirmationCode:
		return "wrong confirmation code"
	case ConfirmEmailErrorCodeHasNotBeenSent:
		return "code has not been sent"
	case ConfirmEmailErrorInternal:
		return "internal error"
	default:
		return "unknown error"
	}
}
