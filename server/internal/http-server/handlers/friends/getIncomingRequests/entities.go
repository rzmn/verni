package getIncomingRequests

import (
	"accounty/internal/http-server/responses"
	"accounty/internal/storage"
)

type Error struct {
	responses.Error
}

func Success(requests []storage.UserId) responses.Response[[]storage.UserId] {
	return responses.Success(requests)
}

func Failure(err Error) responses.Response[responses.Error] {
	return responses.Failure(err.Error)
}

func ErrInternal() Error {
	return Error{responses.Error{Code: responses.CodeInternal}}
}
