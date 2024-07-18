package spendings

import (
	"accounty/internal/auth/jwt"
	"accounty/internal/http-server/handlers/spendings/createDeal"
	"accounty/internal/http-server/handlers/spendings/deleteDeal"
	"accounty/internal/http-server/handlers/spendings/getCounterparties"
	"accounty/internal/http-server/handlers/spendings/getDeals"
	"accounty/internal/http-server/helpers"
	"accounty/internal/http-server/middleware"
	"accounty/internal/storage"

	"github.com/gin-gonic/gin"
)

type createDealRequestHandler struct {
	storage storage.Storage
}

func (h *createDealRequestHandler) Validate(c *gin.Context, request createDeal.Request) *createDeal.Error {
	for i := 0; i < len(request.Deal.Spendings); i++ {
		exists, err := h.storage.IsUserExists(request.Deal.Spendings[i].UserId)
		if err != nil {
			outError := createDeal.ErrInternal()
			return &outError
		}
		if !exists {
			outError := createDeal.ErrNoSuchUser()
			return &outError
		}
	}
	return nil
}

func (h *createDealRequestHandler) Handle(c *gin.Context, request createDeal.Request) ([]storage.SpendingsPreview, *createDeal.Error) {
	if err := h.storage.InsertDeal(request.Deal); err != nil {
		outError := createDeal.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := createDeal.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	preview, err := h.storage.GetCounterparties(storage.UserId(*subject))
	if err != nil {
		outError := createDeal.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	return preview, nil
}

type deleteDealRequestHandler struct {
	storage storage.Storage
}

func (h *deleteDealRequestHandler) Validate(c *gin.Context, request deleteDeal.Request) *deleteDeal.Error {
	exists, err := h.storage.HasDeal(request.DealId)
	if err != nil {
		outError := deleteDeal.ErrInternal()
		return &outError
	}
	if !exists {
		outError := deleteDeal.ErrDealNotFound()
		return &outError
	}
	return nil
}

func (h *deleteDealRequestHandler) Handle(c *gin.Context, request deleteDeal.Request) ([]storage.SpendingsPreview, *deleteDeal.Error) {
	if err := h.storage.RemoveDeal(request.DealId); err != nil {
		outError := deleteDeal.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := deleteDeal.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	preview, err := h.storage.GetCounterparties(storage.UserId(*subject))
	if err != nil {
		outError := deleteDeal.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	return preview, nil
}

type getCounterpartiesRequestHandler struct {
	storage storage.Storage
}

func (h *getCounterpartiesRequestHandler) Handle(c *gin.Context, request getCounterparties.Request) ([]storage.SpendingsPreview, *getCounterparties.Error) {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := getCounterparties.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	preview, err := h.storage.GetCounterparties(storage.UserId(*subject))
	if err != nil {
		outError := getCounterparties.ErrInternal()
		return []storage.SpendingsPreview{}, &outError
	}
	return preview, nil
}

type getDealsRequestHandler struct {
	storage storage.Storage
}

func (h *getDealsRequestHandler) Validate(c *gin.Context, request getDeals.Request) *getDeals.Error {
	exists, err := h.storage.IsUserExists(request.Counterparty)
	if err != nil {
		outError := getDeals.ErrInternal()
		return &outError
	}
	if !exists {
		outError := getDeals.ErrNoSuchUser()
		return &outError
	}
	return nil
}

func (h *getDealsRequestHandler) Handle(c *gin.Context, request getDeals.Request) ([]storage.IdentifiableDeal, *getDeals.Error) {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := getDeals.ErrInternal()
		return []storage.IdentifiableDeal{}, &outError
	}
	deals, err := h.storage.GetDeals(request.Counterparty, storage.UserId(*subject))
	if err != nil {
		outError := getDeals.ErrInternal()
		return []storage.IdentifiableDeal{}, &outError
	}
	return deals, nil
}

func RegisterRoutes(e *gin.Engine, storage storage.Storage) {
	group := e.Group("/spendings", middleware.EnsureLoggedIn())
	group.POST("/createDeal", createDeal.New(&createDealRequestHandler{storage: storage}))
	group.POST("/deleteDeal", deleteDeal.New(&deleteDealRequestHandler{storage: storage}))
	group.GET("/getCounterparties", getCounterparties.New(&getCounterpartiesRequestHandler{storage: storage}))
	group.GET("/getDeals", getDeals.New(&getDealsRequestHandler{storage: storage}))
}
