package auth

import (
	"errors"
	"fmt"
	"log"
	"net/mail"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"

	"accounty/internal/auth/jwt"
	"accounty/internal/storage"

	"accounty/internal/http-server/handlers/auth/login"
	"accounty/internal/http-server/handlers/auth/refresh"
	"accounty/internal/http-server/handlers/auth/signup"
	"accounty/internal/http-server/handlers/auth/updateEmail"
	"accounty/internal/http-server/handlers/auth/updatePassword"
	"accounty/internal/http-server/helpers"
	"accounty/internal/http-server/middleware"
)

func validateUserCredentialsFormat(credentials storage.UserCredentials) error {
	if err := validateEmailFormat(credentials.Email); err != nil {
		return err
	}
	if len(credentials.Password) < 6 {
		return errors.New("`password` field should contain more than 6 characters")
	}
	return nil
}

func validateEmailFormat(email string) error {
	_, err := mail.ParseAddress(email)
	if err != nil {
		return fmt.Errorf("`email` field is invalid: %v", err)
	}
	if strings.TrimSpace(email) != email {
		return fmt.Errorf("`email` field is invalid: leading or trailing spaces")
	}
	return nil
}

type loginRequestHandler struct {
	storage storage.Storage
}

func (h *loginRequestHandler) Validate(request login.Request) *login.Error {
	const op = "router.loginRequestHandler.Validate"

	log.Printf("%s: validating start", op)
	if err := validateUserCredentialsFormat(request.Credentials); err != nil {
		log.Printf("%s: format validating failed %v", op, err)
		outError := login.ErrWrongCredentialsFormat()
		return &outError
	}
	log.Printf("%s: validated format", op)
	log.Printf("%s: checking email/pwd pair matches", op)
	valid, err := h.storage.CheckCredentials(request.Credentials)
	if err != nil {
		log.Printf("%s: checking email/pwd pair matches failed %v", op, err)
		outError := login.ErrInternal()
		return &outError
	}
	log.Printf("%s: checked email/pwd pair matches without errors", op)
	if !valid {
		log.Printf("%s: email/pwd pair did not match", op)
		outError := login.ErrIncorrectCredentials()
		return &outError
	}
	log.Printf("%s: email/pwd pair matches", op)
	return nil
}

func (h *loginRequestHandler) Handle(request login.Request) (*storage.AuthToken, *login.Error) {
	const op = "router.loginRequestHandler.Handle"

	log.Printf("%s: getting uid", op)
	uid, err := h.storage.GetUserId(request.Credentials.Email)
	if err != nil {
		log.Printf("%s: getting uid failed: %v", op, err)
		outError := login.ErrInternal()
		return nil, &outError
	}
	if uid == nil {
		log.Printf("%s: no uid accosiated with email: %s", op, request.Credentials.Email)
		outError := login.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: issuing tokens", op)
	tokens, err := jwt.IssueTokens(string(*uid))
	if err != nil {
		log.Printf("%s: issuing tokens failed %v", op, err)
		outError := login.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: issued tokens ok", op)
	log.Printf("%s: storing refresh token", op)
	if err := h.storage.StoreRefreshToken(tokens.Refresh, *uid); err != nil {
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
	if err := validateUserCredentialsFormat(request.Credentials); err != nil {
		log.Printf("%s: format validating failed %v", op, err)
		outError := signup.ErrWrongCredentialsFormat()
		return &outError
	}
	log.Printf("%s: validated format", op)
	uid, err := h.storage.GetUserId(request.Credentials.Email)
	if err != nil {
		log.Printf("%s: check user exists failed %v", op, err)
		outError := signup.ErrInternal()
		return &outError
	}
	if uid != nil {
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
	uid := storage.UserId(uuid.New().String())
	log.Printf("%s: created new user id %s", op, uid)
	if err := h.storage.StoreCredentials(uid, request.Credentials); err != nil {
		log.Printf("storing credentials failed %v", err)
		outError := signup.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: credentials stored", op)
	tokens, err := jwt.IssueTokens(string(uid))
	if err != nil {
		log.Printf("issue tokens failed %v", err)
		outError := signup.ErrInternal()
		return nil, &outError
	}
	log.Printf("%s: tokens issued", op)
	if err := h.storage.StoreRefreshToken(tokens.Refresh, uid); err != nil {
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

type updateEmailRequestHandler struct {
	storage storage.Storage
}

func (h *updateEmailRequestHandler) Validate(c *gin.Context, request updateEmail.Request) *updateEmail.Error {
	const op = "router.auth.updateEmailRequestHandler.Validate"
	if err := validateEmailFormat(request.Email); err != nil {
		outError := updateEmail.ErrWrongFormat()
		return &outError
	}
	exists, err := h.storage.IsEmailExists(request.Email)
	if err != nil {
		log.Printf("%s: cannot check email existence %v", op, err)
		outError := updateEmail.ErrInternal()
		return &outError
	}
	if exists {
		log.Printf("%s: email already taken %v", op, err)
		outError := updateEmail.ErrCodeAlreadyTaken()
		return &outError
	}
	return nil
}

func (h *updateEmailRequestHandler) Handle(c *gin.Context, request updateEmail.Request) (storage.AuthToken, *updateEmail.Error) {
	const op = "router.auth.updateEmailRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := updateEmail.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	uid := storage.UserId(*subject)
	if err := h.storage.UpdateEmail(uid, request.Email); err != nil {
		log.Printf("%s: cannot update email %v", op, err)
		outError := updateEmail.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	log.Printf("%s: issuing tokens", op)
	tokens, err := jwt.IssueTokens(*subject)
	if err != nil {
		log.Printf("%s: issuing tokens failed %v", op, err)
		outError := updateEmail.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	log.Printf("%s: issued tokens ok", op)
	log.Printf("%s: storing refresh token", op)
	if err := h.storage.StoreRefreshToken(tokens.Refresh, uid); err != nil {
		log.Printf("%s: storing refresh token failed %v", op, err)
		outError := updateEmail.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	log.Printf("%s: storing refresh token ok", op)
	return storage.AuthToken{
		AccessToken:  tokens.Access,
		RefreshToken: tokens.Refresh,
	}, nil
}

type updatePasswordRequestHandler struct {
	storage storage.Storage
}

func (h *updatePasswordRequestHandler) Validate(c *gin.Context, request updatePassword.Request) *updatePassword.Error {
	const op = "router.auth.updatePasswordRequestHandler.Validate"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := updatePassword.ErrInternal()
		return &outError
	}
	uid := storage.UserId(*subject)
	passed, err := h.storage.CheckPasswordForId(uid, request.OldPassword)
	if err != nil {
		log.Printf("%s: cannot check password for id %v", op, err)
		outError := updatePassword.ErrInternal()
		return &outError
	}
	if !passed {
		log.Printf("%s: password did not match", op)
		outError := updatePassword.ErrIncorrectCredentials()
		return &outError
	}
	return nil
}

func (h *updatePasswordRequestHandler) Handle(c *gin.Context, request updatePassword.Request) (storage.AuthToken, *updatePassword.Error) {
	const op = "router.auth.updatePasswordRequestHandler.Handle"
	token := helpers.ExtractBearerToken(c)

	subject, err := jwt.GetAccessTokenSubject(token)
	if err != nil || subject == nil {
		log.Printf("%s: cannot get access token %v", op, err)
		outError := updatePassword.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	uid := storage.UserId(*subject)
	if err := h.storage.UpdatePasswordForId(uid, request.NewPassword); err != nil {
		log.Printf("%s: cannot update password: %v", op, err)
		outError := updatePassword.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	log.Printf("%s: issuing tokens", op)
	tokens, err := jwt.IssueTokens(*subject)
	if err != nil {
		log.Printf("%s: issuing tokens failed %v", op, err)
		outError := updatePassword.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	log.Printf("%s: issued tokens ok", op)
	log.Printf("%s: storing refresh token", op)
	if err := h.storage.StoreRefreshToken(tokens.Refresh, uid); err != nil {
		log.Printf("%s: storing refresh token failed %v", op, err)
		outError := updatePassword.ErrInternal()
		return storage.AuthToken{}, &outError
	}
	log.Printf("%s: storing refresh token ok", op)
	return storage.AuthToken{
		AccessToken:  tokens.Access,
		RefreshToken: tokens.Refresh,
	}, nil
}

func RegisterRoutes(e *gin.Engine, storage storage.Storage) {
	e.PUT("/auth/signup", signup.New(&signupRequestHandler{storage: storage}))
	e.PUT("/auth/login", login.New(&loginRequestHandler{storage: storage}))
	e.PUT("/auth/refresh", refresh.New(&refreshRequestHandler{storage: storage}))
	e.PUT("/auth/updateEmail", middleware.EnsureLoggedIn(storage), updateEmail.New(&updateEmailRequestHandler{storage: storage}))
	e.PUT("/auth/updatePassword", middleware.EnsureLoggedIn(storage), updatePassword.New(&updatePasswordRequestHandler{storage: storage}))
}
