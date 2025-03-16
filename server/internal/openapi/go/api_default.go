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
	"encoding/json"
	"net/http"
	"strings"
)

// DefaultAPIController binds http requests to an api service and writes the service results to the http response
type DefaultAPIController struct {
	service      DefaultAPIServicer
	errorHandler ErrorHandler
}

// DefaultAPIOption for how the controller is set up.
type DefaultAPIOption func(*DefaultAPIController)

// WithDefaultAPIErrorHandler inject ErrorHandler into controller
func WithDefaultAPIErrorHandler(h ErrorHandler) DefaultAPIOption {
	return func(c *DefaultAPIController) {
		c.errorHandler = h
	}
}

// NewDefaultAPIController creates a default api controller
func NewDefaultAPIController(s DefaultAPIServicer, opts ...DefaultAPIOption) *DefaultAPIController {
	controller := &DefaultAPIController{
		service:      s,
		errorHandler: DefaultErrorHandler,
	}

	for _, opt := range opts {
		opt(controller)
	}

	return controller
}

// Routes returns all the api routes for the DefaultAPIController
func (c *DefaultAPIController) Routes() Routes {
	return Routes{
		"Signup": Route{
			strings.ToUpper("Put"),
			"/auth/signup",
			c.Signup,
		},
		"Login": Route{
			strings.ToUpper("Put"),
			"/auth/login",
			c.Login,
		},
		"RefreshSession": Route{
			strings.ToUpper("Put"),
			"/auth/refresh",
			c.RefreshSession,
		},
		"UpdateEmail": Route{
			strings.ToUpper("Put"),
			"/auth/updateEmail",
			c.UpdateEmail,
		},
		"UpdatePassword": Route{
			strings.ToUpper("Put"),
			"/auth/updatePassword",
			c.UpdatePassword,
		},
		"RegisterForPushNotifications": Route{
			strings.ToUpper("Put"),
			"/auth/registerForPushNotifications",
			c.RegisterForPushNotifications,
		},
		"GetAvatars": Route{
			strings.ToUpper("Get"),
			"/avatars/get",
			c.GetAvatars,
		},
		"SearchUsers": Route{
			strings.ToUpper("Get"),
			"/users/search",
			c.SearchUsers,
		},
		"ConfirmEmail": Route{
			strings.ToUpper("Put"),
			"/verification/confirmEmail",
			c.ConfirmEmail,
		},
		"SendEmailConfirmationCode": Route{
			strings.ToUpper("Put"),
			"/verification/sendEmailConfirmationCode",
			c.SendEmailConfirmationCode,
		},
		"PullOperations": Route{
			strings.ToUpper("Get"),
			"/operations/pull",
			c.PullOperations,
		},
		"PushOperations": Route{
			strings.ToUpper("Post"),
			"/operations/push",
			c.PushOperations,
		},
		"ConfirmOperations": Route{
			strings.ToUpper("Post"),
			"/operations/confirm",
			c.ConfirmOperations,
		},
	}
}

// Signup -
func (c *DefaultAPIController) Signup(w http.ResponseWriter, r *http.Request) {
	xDeviceIDParam := r.Header.Get("X-Device-ID")
	signupRequestParam := SignupRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&signupRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertSignupRequestRequired(signupRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertSignupRequestConstraints(signupRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.Signup(r.Context(), xDeviceIDParam, signupRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// Login -
func (c *DefaultAPIController) Login(w http.ResponseWriter, r *http.Request) {
	xDeviceIDParam := r.Header.Get("X-Device-ID")
	loginRequestParam := LoginRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&loginRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertLoginRequestRequired(loginRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertLoginRequestConstraints(loginRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.Login(r.Context(), xDeviceIDParam, loginRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// RefreshSession -
func (c *DefaultAPIController) RefreshSession(w http.ResponseWriter, r *http.Request) {
	refreshSessionRequestParam := RefreshSessionRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&refreshSessionRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertRefreshSessionRequestRequired(refreshSessionRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertRefreshSessionRequestConstraints(refreshSessionRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.RefreshSession(r.Context(), refreshSessionRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// UpdateEmail -
func (c *DefaultAPIController) UpdateEmail(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	updateEmailRequestParam := UpdateEmailRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&updateEmailRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertUpdateEmailRequestRequired(updateEmailRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertUpdateEmailRequestConstraints(updateEmailRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.UpdateEmail(r.Context(), authorizationParam, updateEmailRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// UpdatePassword -
func (c *DefaultAPIController) UpdatePassword(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	updatePasswordRequestParam := UpdatePasswordRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&updatePasswordRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertUpdatePasswordRequestRequired(updatePasswordRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertUpdatePasswordRequestConstraints(updatePasswordRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.UpdatePassword(r.Context(), authorizationParam, updatePasswordRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// RegisterForPushNotifications -
func (c *DefaultAPIController) RegisterForPushNotifications(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	registerForPushNotificationsRequestParam := RegisterForPushNotificationsRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&registerForPushNotificationsRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertRegisterForPushNotificationsRequestRequired(registerForPushNotificationsRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertRegisterForPushNotificationsRequestConstraints(registerForPushNotificationsRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.RegisterForPushNotifications(r.Context(), authorizationParam, registerForPushNotificationsRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// GetAvatars -
func (c *DefaultAPIController) GetAvatars(w http.ResponseWriter, r *http.Request) {
	query, err := parseQuery(r.URL.RawQuery)
	if err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	authorizationParam := r.Header.Get("Authorization")
	var idsParam []string
	if query.Has("ids") {
		idsParam = strings.Split(query.Get("ids"), ",")
	}
	result, err := c.service.GetAvatars(r.Context(), authorizationParam, idsParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// SearchUsers -
func (c *DefaultAPIController) SearchUsers(w http.ResponseWriter, r *http.Request) {
	query, err := parseQuery(r.URL.RawQuery)
	if err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	authorizationParam := r.Header.Get("Authorization")
	var queryParam string
	if query.Has("query") {
		param := query.Get("query")

		queryParam = param
	} else {
		c.errorHandler(w, r, &RequiredError{Field: "query"}, nil)
		return
	}
	result, err := c.service.SearchUsers(r.Context(), authorizationParam, queryParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// ConfirmEmail -
func (c *DefaultAPIController) ConfirmEmail(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	confirmEmailRequestParam := ConfirmEmailRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&confirmEmailRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertConfirmEmailRequestRequired(confirmEmailRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertConfirmEmailRequestConstraints(confirmEmailRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.ConfirmEmail(r.Context(), authorizationParam, confirmEmailRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// SendEmailConfirmationCode -
func (c *DefaultAPIController) SendEmailConfirmationCode(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	result, err := c.service.SendEmailConfirmationCode(r.Context(), authorizationParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// PullOperations -
func (c *DefaultAPIController) PullOperations(w http.ResponseWriter, r *http.Request) {
	query, err := parseQuery(r.URL.RawQuery)
	if err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	authorizationParam := r.Header.Get("Authorization")
	var type_Param OperationType
	if query.Has("type") {
		param := OperationType(query.Get("type"))

		type_Param = param
	} else {
		c.errorHandler(w, r, &RequiredError{Field: "type"}, nil)
		return
	}
	result, err := c.service.PullOperations(r.Context(), authorizationParam, type_Param)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// PushOperations -
func (c *DefaultAPIController) PushOperations(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	pushOperationsRequestParam := PushOperationsRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&pushOperationsRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertPushOperationsRequestRequired(pushOperationsRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertPushOperationsRequestConstraints(pushOperationsRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.PushOperations(r.Context(), authorizationParam, pushOperationsRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}

// ConfirmOperations -
func (c *DefaultAPIController) ConfirmOperations(w http.ResponseWriter, r *http.Request) {
	authorizationParam := r.Header.Get("Authorization")
	confirmOperationsRequestParam := ConfirmOperationsRequest{}
	d := json.NewDecoder(r.Body)
	d.DisallowUnknownFields()
	if err := d.Decode(&confirmOperationsRequestParam); err != nil {
		c.errorHandler(w, r, &ParsingError{Err: err}, nil)
		return
	}
	if err := AssertConfirmOperationsRequestRequired(confirmOperationsRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	if err := AssertConfirmOperationsRequestConstraints(confirmOperationsRequestParam); err != nil {
		c.errorHandler(w, r, err, nil)
		return
	}
	result, err := c.service.ConfirmOperations(r.Context(), authorizationParam, confirmOperationsRequestParam)
	// If an error occurred, encode the error with the status code
	if err != nil {
		c.errorHandler(w, r, err, &result)
		return
	}
	// If no error, encode the body and the result code
	_ = EncodeJSONResponse(result.Body, &result.Code, w)
}
