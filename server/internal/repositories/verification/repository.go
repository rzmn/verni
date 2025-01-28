package verification

import (
	"verni/internal/repositories"
)

type Repository interface {
	StoreEmailVerificationCode(email string, code string) repositories.Transaction
	GetEmailVerificationCode(email string) (*string, error)
	RemoveEmailVerificationCode(email string) repositories.Transaction
}
