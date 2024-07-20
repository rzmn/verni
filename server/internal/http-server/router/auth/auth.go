package auth

import (
	"errors"
	"log"

	"github.com/gin-gonic/gin"

	"accounty/internal/auth/jwt"
	"accounty/internal/storage"

	"accounty/internal/http-server/handlers/auth/login"
	"accounty/internal/http-server/handlers/auth/refresh"
	"accounty/internal/http-server/handlers/auth/signup"
)

func validateUserCredentials(credentials storage.UserCredentials) error {
	if len(credentials.Login) == 0 {
		return errors.New("`login` field is nil or empty")
	}
	if len(credentials.Password) == 0 {
		return errors.New("`password` field is nil or empty")
	}
	return nil
}

type loginRequestHandler struct {
	storage storage.Storage
}

func (h *loginRequestHandler) Validate(request login.Request) *login.Error {
	const op = "router.loginRequestHandler.Validate"

	log.Printf("%s: validating start", op)
	if err := validateUserCredentials(request.Credentials); err != nil {
		log.Printf("%s: format validating failed %v", op, err)
		outError := login.ErrWrongCredentialsFormat()
		return &outError
	}
	log.Printf("%s: validated format", op)
	log.Printf("%s: checking login/pwd pair matches", op)
	valid, err := h.storage.CheckCredentials(request.Credentials)
	if err != nil {
		log.Printf("%s: checking login/pwd pair matches failed %v", op, err)
		outError := login.ErrInternal()
		return &outError
	}
	log.Printf("%s: checked login/pwd pair matches without errors", op)
	if !valid {
		log.Printf("%s: login/pwd pair did not match", op)
		outError := login.ErrIncorrectCredentials()
		return &outError
	}
	log.Printf("%s: login/pwd pair ok", op)
	return nil
}

func (h *loginRequestHandler) Handle(request login.Request) (*storage.AuthToken, *login.Error) {
	const op = "router.loginRequestHandler.Handle"

	log.Printf("%s: issuing tokens", op)
	tokens, err := jwt.IssueTokens(string(request.Credentials.Login))
	if err != nil {
		log.Printf("%s: issuing tokens failed %v", op, err)
		outError := login.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: issued tokens ok", op)
	log.Printf("%s: storing refresh token", op)
	if err := h.storage.StoreRefreshToken(tokens.Refresh, request.Credentials.Login); err != nil {
		log.Printf("%s: storing refresh token failed %v", op, err)
		outError := login.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: storing refresh token ok", op)
	return &storage.AuthToken{
		AccessToken:  tokens.Access,
		RefreshToken: tokens.Refresh,
	}, nil
}

type signupRequestHandler struct {
	storage storage.Storage
}

func (h *signupRequestHandler) Validate(request signup.Request) *signup.Error {
	const op = "router.signupRequestHandler.Validate"
	log.Printf("%s: start with request %v", op, request)
	if err := validateUserCredentials(request.Credentials); err != nil {
		log.Printf("%s: format validating failed %v", op, err)
		outError := signup.ErrWrongCredentialsFormat()
		return &outError
	}
	log.Printf("%s: validated format", op)
	exists, err := h.storage.IsUserExists(request.Credentials.Login)
	if err != nil {
		log.Printf("%s: check exists failed %v", op, err)
		outError := signup.ErrInternal()
		return &outError
	}
	log.Printf("%s: existance check ran without errors", op)
	if exists {
		log.Printf("%s: already taken", op)
		outError := signup.ErrLoginAlreadyTaken()
		return &outError
	}
	log.Printf("%s: existance check ok", op)
	return nil
}

func (h *signupRequestHandler) Handle(request signup.Request) (*storage.AuthToken, *signup.Error) {
	const op = "router.signupRequestHandler.Handle"
	log.Printf("%s: start with request %v", op, request)
	if err := h.storage.StoreCredentials(request.Credentials); err != nil {
		log.Printf("storing credentials failed %v", err)
		outError := signup.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: credentials stored", op)
	tokens, err := jwt.IssueTokens(string(request.Credentials.Login))
	if err != nil {
		log.Printf("issue tokens failed %v", err)
		outError := signup.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: tokens issued", op)
	if err := h.storage.StoreRefreshToken(tokens.Refresh, request.Credentials.Login); err != nil {
		log.Printf("store tokens failed %v", err)
		outError := signup.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: tokens stored", op)
	log.Printf("%s: ok", op)
	return &storage.AuthToken{
		AccessToken:  tokens.Access,
		RefreshToken: tokens.Refresh,
	}, nil
}

type refreshRequestHandler struct {
	storage storage.Storage
}

func (h *refreshRequestHandler) Handle(request refresh.Request) (*storage.AuthToken, *refresh.Error) {
	const op = "router.refreshRequestHandler.Handle"
	log.Printf("%s: start with request %v", op, request)
	refreshedTokens, err := jwt.IssueTokensBasedOnRefreshToken(request.RefreshToken)
	if err != nil {
		if errors.Is(err, jwt.ErrTokenExpired) {
			outError := refresh.ErrTokenExpired()
			return nil, &outError
		} else if errors.Is(err, jwt.ErrBadToken) {
			outError := refresh.ErrWrongAccessToken()
			return nil, &outError
		} else {
			outError := refresh.ErrInternal()
			return nil, &outError
		}
	}
	tokenFromDb, err := h.storage.GetRefreshToken(storage.UserId(refreshedTokens.Subject))
	if err != nil {
		outError := refresh.ErrInternal()
		return nil, &outError
	}
	if tokenFromDb != nil && *tokenFromDb != request.RefreshToken {
		outError := refresh.ErrWrongAccessToken()
		return nil, &outError
	}
	if err := h.storage.StoreRefreshToken(refreshedTokens.Refresh, storage.UserId(refreshedTokens.Subject)); err != nil {
		outError := refresh.ErrInternal()
		return nil, &outError
	}
	return &storage.AuthToken{
		AccessToken:  refreshedTokens.Access,
		RefreshToken: refreshedTokens.Refresh,
	}, nil
}

func RegisterRoutes(e *gin.Engine, storage storage.Storage) {
	e.PUT("/auth/signup", signup.New(&signupRequestHandler{storage: storage}))
	e.PUT("/auth/login", login.New(&loginRequestHandler{storage: storage}))
	e.PUT("/auth/refresh", refresh.New(&refreshRequestHandler{storage: storage}))
}
