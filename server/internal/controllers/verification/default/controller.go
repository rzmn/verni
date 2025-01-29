package defaultController

import (
	"fmt"
	"math/rand"

	"verni/internal/controllers/verification"
	authRepository "verni/internal/repositories/auth"
	verificationRepository "verni/internal/repositories/verification"
	"verni/internal/services/emailSender"
	"verni/internal/services/logging"
)

type VerificationRepository verificationRepository.Repository
type AuthRepository authRepository.Repository

func New(
	verification VerificationRepository,
	auth AuthRepository,
	emailService emailSender.Service,
	logger logging.Service,
) verification.Controller {
	return &defaultController{
		verification: verification,
		auth:         auth,
		emailService: emailService,
		logger:       logger,
	}
}

type defaultController struct {
	verification VerificationRepository
	auth         AuthRepository
	emailService emailSender.Service
	logger       logging.Service
}

func (c *defaultController) SendConfirmationCode(uid verification.UserId) error {
	const op = "confirmation.EmailConfirmation.SendConfirmationCode"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	user, err := c.auth.GetUserInfo(authRepository.UserId(uid))
	if err != nil {
		err := fmt.Errorf("getting user by email: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	email := user.Email
	code := fmt.Sprintf("%d", generate6DigitCode())
	transaction := c.verification.StoreEmailVerificationCode(email, code)
	if err := transaction.Perform(); err != nil {
		err := fmt.Errorf("storing verification code: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	if err := c.emailService.Send(
		"Subject: Confirm your Verni email\r\n"+
			"\r\n"+
			fmt.Sprintf("Email Verification code: %s.\r\n", code),
		email,
	); err != nil {
		transaction.Rollback()
		c.logger.LogInfo("%s: send failed: %v", op, err)
		return fmt.Errorf("sending verification code: %w", verification.CodeNotDelivered)
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, uid)
	return nil
}

func (c *defaultController) ConfirmEmail(uid verification.UserId, code string) error {
	const op = "confirmation.EmailConfirmation.ConfirmEmail"
	c.logger.LogInfo("%s: start[uid=%s]", op, uid)
	user, err := c.auth.GetUserInfo(authRepository.UserId(uid))
	if err != nil {
		err := fmt.Errorf("getting user by email: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	email := user.Email
	codeFromDb, err := c.verification.GetEmailVerificationCode(email)
	if err != nil {
		err := fmt.Errorf("getting verification code: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	if codeFromDb == nil {
		c.logger.LogInfo("%s: code has not been sent", op)
		return fmt.Errorf("checking if verification code exists: %w", verification.CodeHasNotBeenSent)
	}
	if *codeFromDb != code {
		c.logger.LogInfo("%s: verification code is wrong", op)
		return fmt.Errorf("checking verification matches: %w", verification.WrongConfirmationCode)
	}
	transaction := c.auth.MarkUserEmailValidated(authRepository.UserId(uid))
	if err := transaction.Perform(); err != nil {
		err := fmt.Errorf("marking verification code as validated: %w", err)
		c.logger.LogInfo("%s: %v", op, err)
		return err
	}
	c.logger.LogInfo("%s: success[uid=%s]", op, uid)
	return nil
}

func generate6DigitCode() int {
	max := 999999
	min := 100000
	return rand.Intn(max-min) + min
}
