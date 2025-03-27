package pushNotifications

type Token string

type Service interface {
	Alert(token Token, title string, subtitle *string, body *string, data interface{}) error
}
