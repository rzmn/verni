package profile

import (
	"accounty/internal/auth/jwt"
	"accounty/internal/http-server/handlers/profile/getInfo"
	"accounty/internal/http-server/helpers"
	"accounty/internal/http-server/middleware"
	"accounty/internal/storage"
	"log"

	"github.com/gin-gonic/gin"
)

type getInfoRequestHandler struct {
	storage storage.Storage
}

func (h *getInfoRequestHandler) Handle(c *gin.Context) (storage.ProfileInfo, *getInfo.Error) {
	const op = "router.users.getInfoRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := getInfo.ErrInternal()
		return storage.ProfileInfo{}, &outError
	}
	info, err := h.storage.GetAccountInfo(storage.UserId(*subject))
	if err != nil {
		log.Printf("%s: cannot get host info %v", op, err)
		outError := getInfo.ErrInternal()
		return storage.ProfileInfo{}, &outError
	}
	if info == nil {
		log.Printf("%s: profile not found", op)
		outError := getInfo.ErrInternal()
		return storage.ProfileInfo{}, &outError
	}
	return *info, nil
}

func RegisterRoutes(e *gin.Engine, storage storage.Storage) {
	group := e.Group("/profile", middleware.EnsureLoggedIn(storage))
	group.GET("/getMyInfo", getInfo.New(&getInfoRequestHandler{storage: storage}))
}
