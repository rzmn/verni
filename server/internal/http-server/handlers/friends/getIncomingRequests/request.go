package getIncomingRequests

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"accounty/internal/storage"
)

type RequestHandler interface {
	Handle(c *gin.Context) ([]storage.UserId, *Error)
}

func handleError(c *gin.Context, err Error) {
	switch err.Code {
	default:
		c.JSON(http.StatusInternalServerError, Failure(err))
	}
}

func New(requestHandler RequestHandler) func(c *gin.Context) {
	return func(c *gin.Context) {
		requests, err := requestHandler.Handle(c)
		if err != nil {
			handleError(c, *err)
			return
		}
		c.JSON(http.StatusCreated, Success(requests))
	}
}
