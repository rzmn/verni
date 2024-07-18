package getDeals

import (
	"accounty/internal/http-server/responses"
	"accounty/internal/storage"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
)

type RequestHandler interface {
	Validate(c *gin.Context, request Request) *Error
	Handle(c *gin.Context, request Request) ([]storage.IdentifiableDeal, *Error)
}

func handleError(c *gin.Context, err Error) {
	switch err.Code {
	case responses.CodeNoSuchUser:
		c.JSON(http.StatusConflict, Failure(err))
	case responses.CodeBadRequest:
		c.JSON(http.StatusBadRequest, Failure(err))
	default:
		c.JSON(http.StatusInternalServerError, Failure(err))
	}
}

func New(requestHandler RequestHandler) func(c *gin.Context) {
	return func(c *gin.Context) {
		const op = "handlers.spendings.getDeals"

		requestQueryString := c.Query("data")
		log.Printf("%s: got data param: %s", op, requestQueryString)
		request := Request{}

		if err := json.Unmarshal([]byte(requestQueryString), &request); err != nil {
			handleError(c, ErrBadRequest(fmt.Sprintf("%s: request failed %v", op, err)))
			return
		}
		if err := requestHandler.Validate(c, request); err != nil {
			handleError(c, *err)
			return
		}
		deals, err := requestHandler.Handle(c, request)
		if err != nil {
			handleError(c, *err)
			return
		}
		c.JSON(http.StatusOK, Success(deals))
	}
}
