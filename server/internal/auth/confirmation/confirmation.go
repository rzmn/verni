package confirmation

import (
	"accounty/internal/storage"
	"fmt"
	"log"
	"math/rand"
	"net/smtp"
	"os"
)

type EmailConfirmation struct {
	s storage.Storage
}

func (e *EmailConfirmation) SendConfirmationCode(email string) error {
	const op = "confirmation.EmailConfirmation.SendConfirmationCode"
	code := generate6DigitCode()
	if err := e.s.StoreEmailValidationToken(email, fmt.Sprintf("%d", code)); err != nil {
		log.Printf("%s: store tokens failed %v", op, err)
		return err
	}
	from := os.Getenv("EMAIL_CODE_SENDER")
	password := os.Getenv("EMAIL_CODE_SENDER_PWD")

	to := []string{
		email,
	}

	smtpHost := os.Getenv("EMAIL_CODE_SENDER_HOST")
	smtpPort := os.Getenv("EMAIL_CODE_SENDER_PORT")

	message := []byte(fmt.Sprintf("Confirmation code: %d", code))
	auth := smtp.PlainAuth("", from, password, smtpHost)

	err := smtp.SendMail(smtpHost+":"+smtpPort, auth, from, to, message)
	if err != nil {
		log.Printf("%s: send failed: %v", op, err)
		_, _ = e.s.ExtractEmailValidationToken(email)
		return err
	}
	return nil
}

func generate6DigitCode() int {
	max := 999999
	min := 100000
	return rand.Intn(max-min) + min
}
