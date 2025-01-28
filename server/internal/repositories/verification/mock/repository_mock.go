package verification_mock

import "verni/internal/repositories"

type RepositoryMock struct {
	StoreEmailVerificationCodeImpl  func(email string, code string) repositories.Transaction
	GetEmailVerificationCodeImpl    func(email string) (*string, error)
	RemoveEmailVerificationCodeImpl func(email string) repositories.Transaction
}

func (c *RepositoryMock) StoreEmailVerificationCode(email string, code string) repositories.Transaction {
	return c.StoreEmailVerificationCodeImpl(email, code)
}
func (c *RepositoryMock) GetEmailVerificationCode(email string) (*string, error) {
	return c.GetEmailVerificationCodeImpl(email)
}
func (c *RepositoryMock) RemoveEmailVerificationCode(email string) repositories.Transaction {
	return c.RemoveEmailVerificationCodeImpl(email)
}
