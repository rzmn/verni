package common

func Map[T, U any](ts []T, f func(T) U) []U {
	us := make([]U, len(ts))
	for i := range ts {
		us[i] = f(ts[i])
	}
	return us
}

func Filter[T any](ts []T, f func(T) bool) []T {
	us := make([]T, 0)
	for _, t := range ts {
		if f(t) {
			us = append(us, t)
		}
	}
	return us
}
