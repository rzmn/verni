package repositories

type UnitOfWork struct {
	Perform  func() error
	Rollback func() error
}
