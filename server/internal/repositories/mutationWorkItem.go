package repositories

type Transaction struct {
	Perform  func() error
	Rollback func() error
}

type TransactionWithReturnValue[T any] struct {
	Perform  func() (T, error)
	Rollback func() error
}
