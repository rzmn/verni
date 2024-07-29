package signup

import (
	"accounty/internal/http-server/responses"
	"accounty/internal/storage"
)

type Request struct {
	Credentials storage.UserCredentials `json:"credentials"`
}

type Error struct {
	responses.Error
}

func Success(token storage.AuthToken) responses.Response[storage.AuthToken] {
	return responses.Success(token)
}

func Failure(err Error) responses.Response[responses.Error] {
	return responses.Failure(err.Error)
}

func ErrWrongCredentialsFormat() Error {
	return Error{responses.Error{Code: responses.CodeWrongFormat}}
}

func ErrLoginAlreadyTaken() Error {
	return Error{responses.Error{Code: responses.CodeLoginAlreadyTaken}}
}

func ErrBadRequest(description string) Error {
	return Error{responses.Error{Code: responses.CodeBadRequest, Description: &description}}
}

func ErrInternal() Error {
	return Error{responses.Error{Code: responses.CodeInternal}}
}
