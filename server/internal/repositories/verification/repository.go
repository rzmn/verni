package verification

import (
	"verni/internal/repositories"
)

type Repository interface {
	StoreEmailVerificationCode(email string, code string) repositories.UnitOfWork
	GetEmailVerificationCode(email string) (*string, error)
	RemoveEmailVerificationCode(email string) repositories.UnitOfWork
}
