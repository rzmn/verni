package friends

import (
	"log"
	"slices"

	"github.com/gin-gonic/gin"

	"accounty/internal/auth/jwt"
	"accounty/internal/storage"

	"accounty/internal/http-server/handlers/friends/acceptRequest"
	"accounty/internal/http-server/handlers/friends/get"
	"accounty/internal/http-server/handlers/friends/rejectRequest"
	"accounty/internal/http-server/handlers/friends/rollbackRequest"
	"accounty/internal/http-server/handlers/friends/sendRequest"
	"accounty/internal/http-server/handlers/friends/unfriend"
	"accounty/internal/http-server/helpers"
	"accounty/internal/http-server/middleware"
)

type sendRequestRequestHandler struct {
	storage storage.Storage
}

func (h *sendRequestRequestHandler) Validate(c *gin.Context, request sendRequest.Request) *sendRequest.Error {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := sendRequest.ErrInternal()
		return &outError
	}
	hasTarget, err := h.storage.IsUserExists(request.Target)
	if err != nil {
		outError := sendRequest.ErrInternal()
		return &outError
	} else if !hasTarget {
		outError := sendRequest.ErrNoSuchUser()
		return &outError
	}
	hasRequest, err := h.storage.HasFriendRequest(storage.UserId(*subject), request.Target)
	if err != nil {
		outError := sendRequest.ErrInternal()
		return &outError
	} else if hasRequest {
		outError := sendRequest.ErrAlreadySend()
		return &outError
	}
	hasIncomingRequest, err := h.storage.HasFriendRequest(request.Target, storage.UserId(*subject))
	if err != nil {
		outError := sendRequest.ErrInternal()
		return &outError
	} else if hasIncomingRequest {
		outError := sendRequest.ErrHaveIncomingRequest()
		return &outError
	}
	isFriends, err := h.storage.HasFriendship(request.Target, storage.UserId(*subject))
	if err != nil {
		outError := sendRequest.ErrInternal()
		return &outError
	} else if isFriends {
		outError := sendRequest.ErrAlreadyFriends()
		return &outError
	}
	return nil
}

func (h *sendRequestRequestHandler) Handle(c *gin.Context, request sendRequest.Request) *sendRequest.Error {
	const op = "router.friends.sendRequestRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := sendRequest.ErrInternal()
		return &outError
	}
	if err := h.storage.StoreFriendRequest(storage.UserId(*subject), request.Target); err != nil {
		outError := sendRequest.ErrInternal()
		return &outError
	}
	return nil
}

type acceptRequestRequestHandler struct {
	storage storage.Storage
}

func (h *acceptRequestRequestHandler) Validate(c *gin.Context, request acceptRequest.Request) *acceptRequest.Error {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := acceptRequest.ErrInternal()
		return &outError
	}
	hasRequest, err := h.storage.HasFriendRequest(request.Sender, storage.UserId(*subject))
	if err != nil {
		outError := acceptRequest.ErrInternal()
		return &outError
	} else if !hasRequest {
		outError := acceptRequest.ErrNoSuchRequest()
		return &outError
	}
	return nil
}

func (h *acceptRequestRequestHandler) Handle(c *gin.Context, request acceptRequest.Request) *acceptRequest.Error {
	const op = "router.friends.acceptRequestRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := acceptRequest.ErrInternal()
		return &outError
	}
	if err := h.storage.RemoveFriendRequest(request.Sender, storage.UserId(*subject)); err != nil {
		outError := acceptRequest.ErrInternal()
		return &outError
	}
	if err := h.storage.StoreFriendship(request.Sender, storage.UserId(*subject)); err != nil {
		outError := acceptRequest.ErrInternal()
		return &outError
	}
	return nil
}

type getRequestHandler struct {
	storage storage.Storage
}

func (h *getRequestHandler) Handle(c *gin.Context, request get.Request) (map[get.Status][]storage.UserId, *get.Error) {
	const op = "router.friends.getRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := get.ErrInternal()
		return map[get.Status][]storage.UserId{}, &outError
	}
	friends := map[get.Status][]storage.UserId{}
	if slices.Contains(request.Statuses, get.FriendStatusFriends) {
		logins, err := h.storage.GetFriends(storage.UserId(*subject))
		if err != nil {
			outError := get.ErrInternal()
			return map[get.Status][]storage.UserId{}, &outError
		}
		for i := range logins {
			friends[get.FriendStatusFriends] = append(friends[get.FriendStatusFriends], storage.UserId(logins[i]))
		}
	}
	if slices.Contains(request.Statuses, get.FriendStatusSubscriber) {
		logins, err := h.storage.GetIncomingRequests(storage.UserId(*subject))
		if err != nil {
			outError := get.ErrInternal()
			return map[get.Status][]storage.UserId{}, &outError
		}
		for i := range logins {
			friends[get.FriendStatusSubscriber] = append(friends[get.FriendStatusSubscriber], storage.UserId(logins[i]))
		}
	}
	if slices.Contains(request.Statuses, get.FriendStatusSubscription) {
		logins, err := h.storage.GetPendingRequests(storage.UserId(*subject))
		if err != nil {
			outError := get.ErrInternal()
			return map[get.Status][]storage.UserId{}, &outError
		}
		for i := range logins {
			friends[get.FriendStatusSubscription] = append(friends[get.FriendStatusSubscription], storage.UserId(logins[i]))
		}
	}
	return friends, nil
}

// type getIncomingRequestsRequestHandler struct {
// 	storage *sqlite.Storage
// }

// func (h *getIncomingRequestsRequestHandler) Handle(c *gin.Context) ([]storage.UserId, *getIncomingRequests.Error) {
// 	const op = "router.friends.getIncomingRequestsRequestHandler.Handle"
// 	token := helpers.ExtractBearerToken(c)

// 	subject, err := jwt.GetAccessTokenSubject(token)
// 	if err != nil || subject == nil {
// 		log.Printf("%s: cannot get access token %v", op, err)
// 		outError := getIncomingRequests.ErrInternal()
// 		return []storage.UserId{}, &outError
// 	}
// 	logins, err := h.storage.GetIncomingRequests(*subject)
// 	if err != nil {
// 		outError := getIncomingRequests.ErrInternal()
// 		return []storage.UserId{}, &outError
// 	}
// 	requests := make([]storage.UserId, len(logins))
// 	for i := range logins {
// 		requests[i] = storage.UserId(logins[i])
// 	}
// 	return requests, nil
// }

// type getPendingRequestsRequestHandler struct {
// 	storage *sqlite.Storage
// }

// func (h *getPendingRequestsRequestHandler) Handle(c *gin.Context) ([]storage.UserId, *getPendingRequests.Error) {
// 	const op = "router.friends.getPendingRequestsHandler.Handle"
// 	token := helpers.ExtractBearerToken(c)

// 	subject, err := jwt.GetAccessTokenSubject(token)
// 	if err != nil || subject == nil {
// 		log.Printf("%s: cannot get access token %v", op, err)
// 		outError := getPendingRequests.ErrInternal()
// 		return []storage.UserId{}, &outError
// 	}
// 	logins, err := h.storage.GetPendingRequests(*subject)
// 	if err != nil {
// 		outError := getPendingRequests.ErrInternal()
// 		return []storage.UserId{}, &outError
// 	}
// 	requests := make([]storage.UserId, len(logins))
// 	for i := range logins {
// 		requests[i] = storage.UserId(logins[i])
// 	}
// 	return requests, nil
// }

type rejectRequestRequestHandler struct {
	storage storage.Storage
}

func (h *rejectRequestRequestHandler) Validate(c *gin.Context, request rejectRequest.Request) *rejectRequest.Error {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := rejectRequest.ErrInternal()
		return &outError
	}
	hasRequest, err := h.storage.HasFriendRequest(request.Sender, storage.UserId(*subject))
	if err != nil {
		outError := rejectRequest.ErrInternal()
		return &outError
	} else if !hasRequest {
		outError := rejectRequest.ErrNoSuchRequest()
		return &outError
	}
	return nil
}

func (h *rejectRequestRequestHandler) Handle(c *gin.Context, request rejectRequest.Request) *rejectRequest.Error {
	const op = "router.friends.acceptRequestRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := rejectRequest.ErrInternal()
		return &outError
	}
	if err := h.storage.RemoveFriendRequest(request.Sender, storage.UserId(*subject)); err != nil {
		outError := rejectRequest.ErrInternal()
		return &outError
	}
	return nil
}

type rollbackRequestRequestHandler struct {
	storage storage.Storage
}

func (h *rollbackRequestRequestHandler) Validate(c *gin.Context, request rollbackRequest.Request) *rollbackRequest.Error {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := rollbackRequest.ErrInternal()
		return &outError
	}
	hasRequest, err := h.storage.HasFriendRequest(storage.UserId(*subject), request.Target)
	if err != nil {
		outError := rollbackRequest.ErrInternal()
		return &outError
	} else if !hasRequest {
		outError := rollbackRequest.ErrNoSuchRequest()
		return &outError
	}
	return nil
}

func (h *rollbackRequestRequestHandler) Handle(c *gin.Context, request rollbackRequest.Request) *rollbackRequest.Error {
	const op = "router.friends.rollbackRequestRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := rollbackRequest.ErrInternal()
		return &outError
	}
	if err := h.storage.RemoveFriendRequest(storage.UserId(*subject), request.Target); err != nil {
		outError := rollbackRequest.ErrInternal()
		return &outError
	}
	return nil
}

type unfriendRequestHandler struct {
	storage storage.Storage
}

func (h *unfriendRequestHandler) Validate(c *gin.Context, request unfriend.Request) *unfriend.Error {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := unfriend.ErrInternal()
		return &outError
	}
	hasTarget, err := h.storage.IsUserExists(request.Target)
	if err != nil {
		outError := unfriend.ErrInternal()
		return &outError
	} else if !hasTarget {
		outError := unfriend.ErrNoSuchUser()
		return &outError
	}
	isFriends, err := h.storage.HasFriendship(request.Target, storage.UserId(*subject))
	if err != nil {
		outError := unfriend.ErrInternal()
		return &outError
	} else if !isFriends {
		outError := unfriend.ErrNotAFriend()
		return &outError
	}
	return nil
}

func (h *unfriendRequestHandler) Handle(c *gin.Context, request unfriend.Request) *unfriend.Error {
	token := helpers.ExtractBearerToken(c)
	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		outError := unfriend.ErrInternal()
		return &outError
	}
	if err := h.storage.RemoveFriendship(request.Target, storage.UserId(*subject)); err != nil {
		outError := unfriend.ErrInternal()
		return &outError
	}
	if err := h.storage.StoreFriendRequest(request.Target, storage.UserId(*subject)); err != nil {
		outError := unfriend.ErrInternal()
		return &outError
	}
	return nil
}

func RegisterRoutes(e *gin.Engine, storage storage.Storage) {
	group := e.Group("/friends", middleware.EnsureLoggedIn())
	group.POST("/sendRequest", sendRequest.New(&sendRequestRequestHandler{storage: storage}))
	group.POST("/acceptRequest", acceptRequest.New(&acceptRequestRequestHandler{storage: storage}))
	group.POST("/rejectRequest", rejectRequest.New(&rejectRequestRequestHandler{storage: storage}))
	group.POST("/rollbackRequest", rollbackRequest.New(&rollbackRequestRequestHandler{storage: storage}))
	group.POST("/unfriend", unfriend.New(&unfriendRequestHandler{storage: storage}))
	group.GET("/get", get.New(&getRequestHandler{storage: storage}))
	// group.GET("/getIncomingRequests", getIncomingRequests.New(&getIncomingRequestsRequestHandler{storage: storage}))
	// group.GET("/getPendingRequests", getPendingRequests.New(&getPendingRequestsRequestHandler{storage: storage}))
}
