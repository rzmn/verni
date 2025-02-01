// Code generated by OpenAPI Generator (https://openapi-generator.tech); DO NOT EDIT.

/*
 * Verni
 *
 * No description provided (generated by Openapi Generator https://github.com/openapitools/openapi-generator)
 *
 * API version: 0.0.1
 */

package openapi

import (
	"context"
	"net/http"
	"reflect"
)

// DefaultAPIRouter defines the required methods for binding the api requests to a responses for the DefaultAPI
// The DefaultAPIRouter implementation should parse necessary information from the http request,
// pass the data to a DefaultAPIServicer to perform the required actions, then write the service results to the http response.
type DefaultAPIRouter interface {
	Signup(http.ResponseWriter, *http.Request)
	Login(http.ResponseWriter, *http.Request)
	RefreshSession(http.ResponseWriter, *http.Request)
	UpdateEmail(http.ResponseWriter, *http.Request)
	UpdatePassword(http.ResponseWriter, *http.Request)
	RegisterForPushNotifications(http.ResponseWriter, *http.Request)
	GetAvatars(http.ResponseWriter, *http.Request)
	SearchUsers(http.ResponseWriter, *http.Request)
	ConfirmEmail(http.ResponseWriter, *http.Request)
	SendEmailConfirmationCode(http.ResponseWriter, *http.Request)
	PullOperations(http.ResponseWriter, *http.Request)
	PushOperations(http.ResponseWriter, *http.Request)
	ConfirmOperations(http.ResponseWriter, *http.Request)
}

// DefaultAPIServicer defines the api actions for the DefaultAPI service
// This interface intended to stay up to date with the openapi yaml used to generate it,
// while the service implementation can be ignored with the .openapi-generator-ignore file
// and updated with the logic required for the API.
type DefaultAPIServicer interface {
	Signup(context.Context, string, SignupRequest) (ImplResponse, error)
	Login(context.Context, string, LoginRequest) (ImplResponse, error)
	RefreshSession(context.Context, RefreshSessionRequest) (ImplResponse, error)
	UpdateEmail(context.Context, string, UpdateEmailRequest) (ImplResponse, error)
	UpdatePassword(context.Context, string, UpdatePasswordRequest) (ImplResponse, error)
	RegisterForPushNotifications(context.Context, string, RegisterForPushNotificationsRequest) (ImplResponse, error)
	GetAvatars(context.Context, string, []string) (ImplResponse, error)
	SearchUsers(context.Context, string, string) (ImplResponse, error)
	ConfirmEmail(context.Context, string, ConfirmEmailRequest) (ImplResponse, error)
	SendEmailConfirmationCode(context.Context, string) (ImplResponse, error)
	PullOperations(context.Context, string) (ImplResponse, error)
	PushOperations(context.Context, string, PushOperationsRequest) (ImplResponse, error)
	ConfirmOperations(context.Context, string, []string) (ImplResponse, error)
}
