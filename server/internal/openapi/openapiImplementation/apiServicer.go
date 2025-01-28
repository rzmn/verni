package openapiImplementation

import (
	"context"
	"strings"

	"verni/internal/common"
	"verni/internal/controllers/auth"
	"verni/internal/controllers/avatars"
	"verni/internal/controllers/profile"
	"verni/internal/controllers/spendings"
	"verni/internal/controllers/users"
	"verni/internal/controllers/verification"
	openapi "verni/internal/openapi/go"
	spendingsRepository "verni/internal/repositories/spendings"
	"verni/internal/services/logging"
)

// DefaultAPIService is a service that implements the logic for the DefaultAPIServicer
// This service should implement the business logic for every endpoint for the DefaultAPI API.
// Include any external packages or services that will be required by this service.
type DefaultAPIService struct {
	Auth         auth.Controller
	Spendings    spendings.Controller
	Profile      profile.Controller
	Verification verification.Controller
	Users        users.Controller
	Avatars      avatars.Controller
	logger       logging.Service
}

func extractToken(authorizationHeaderValue string) string {
	splitted := strings.Split(authorizationHeaderValue, " ")
	if len(splitted) != 2 {
		return ""
	}
	return splitted[1]
}

func makeResponse(tokenCheckError common.CodeBasedError[auth.CheckTokenErrorCode]) openapi.ImplResponse {
	return openapi.Response(401, openapi.ErrorResponse{
		Error: openapi.Error{
			Reason: func() openapi.ErrorReason {
				switch tokenCheckError.Code {
				case auth.CheckTokenErrorTokenExpired:
					return openapi.TOKEN_EXPIRED
				case auth.CheckTokenErrorTokenIsWrong:
					return openapi.WRONG_ACCESS_TOKEN
				case auth.CheckTokenErrorTokenOwnedByUnknownUser:
					return openapi.NO_SUCH_USER
				default:
					return openapi.INTERNAL
				}
			}(),
			Description: tokenCheckError.Description,
		},
	})
}

// NewDefaultAPIService creates a default api service
func NewDefaultAPIService() *DefaultAPIService {
	return &DefaultAPIService{}
}

// Signup -
func (s *DefaultAPIService) Signup(ctx context.Context, authorization string, request openapi.SignupRequest) (openapi.ImplResponse, error) {
	session, err := s.Auth.Signup(request.Credentials.Email, request.Credentials.Password)
	if err != nil {
		switch err.Code {
		case auth.SignupErrorAlreadyTaken:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.ALREADY_TAKEN,
					Description: err.Description,
				},
			}), nil
		case auth.SignupErrorWrongFormat:
			return openapi.Response(422, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.WRONG_FORMAT,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("signup request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.SignupSucceededResponse{
		Response: sessionToOpenapi(session),
	}), nil
}

// Login -
func (s *DefaultAPIService) Login(ctx context.Context, authorization string, request openapi.LoginRequest) (openapi.ImplResponse, error) {
	session, err := s.Auth.Login(request.Credentials.Email, request.Credentials.Password)
	if err != nil {
		switch err.Code {
		case auth.LoginErrorWrongCredentials:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INCORRECT_CREDENTIALS,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("login request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.LoginSucceededResponse{
		Response: sessionToOpenapi(session),
	}), nil
}

// RefreshSession -
func (s *DefaultAPIService) RefreshSession(ctx context.Context, request openapi.RefreshSessionRequest) (openapi.ImplResponse, error) {
	session, err := s.Auth.Refresh(request.RefreshToken)
	if err != nil {
		switch err.Code {
		case auth.RefreshErrorTokenExpired:
			return openapi.Response(401, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.TOKEN_EXPIRED,
					Description: err.Description,
				},
			}), nil
		case auth.RefreshErrorTokenIsWrong:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.WRONG_ACCESS_TOKEN,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("refresh request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.RefreshSucceededResponse{
		Response: sessionToOpenapi(session),
	}), nil
}

// UpdateEmail -
func (s *DefaultAPIService) UpdateEmail(ctx context.Context, authorization string, request openapi.UpdateEmailRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	session, err := s.Auth.UpdateEmail(request.Email, user)
	if err != nil {
		switch err.Code {
		case auth.UpdateEmailErrorAlreadyTaken:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.ALREADY_TAKEN,
					Description: err.Description,
				},
			}), nil
		case auth.UpdateEmailErrorWrongFormat:
			return openapi.Response(422, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.WRONG_FORMAT,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("update email request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.UpdateEmailSucceededResponse{
		Response: sessionToOpenapi(session),
	}), nil
}

// UpdatePassword -
func (s *DefaultAPIService) UpdatePassword(ctx context.Context, authorization string, request openapi.UpdatePasswordRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	session, err := s.Auth.UpdatePassword(request.Old, request.New, user)
	if err != nil {
		switch err.Code {
		case auth.UpdatePasswordErrorOldPasswordIsWrong:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INCORRECT_CREDENTIALS,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("update password request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.UpdatePasswordSucceededResponse{
		Response: sessionToOpenapi(session),
	}), nil
}

// RegisterForPushNotifications -
func (s *DefaultAPIService) RegisterForPushNotifications(ctx context.Context, authorization string, request openapi.RegisterForPushNotificationsRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	if err := s.Auth.RegisterForPushNotifications(request.Token, user); err != nil {
		switch err.Code {
		default:
			s.logger.LogError("register push token request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.RegisterForPushNotificationsSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

// Logout -
func (s *DefaultAPIService) Logout(ctx context.Context, authorization string) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	if err := s.Auth.Logout(user); err != nil {
		switch err.Code {
		default:
			s.logger.LogError("logout request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.LogoutSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

// GetAvatars -
func (s *DefaultAPIService) GetAvatars(ctx context.Context, authorization string, ids []string) (openapi.ImplResponse, error) {
	_, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	result, err := s.Avatars.GetAvatars(common.Map(ids, func(s string) avatars.AvatarId {
		return avatars.AvatarId(s)
	}))
	if err != nil {
		switch err.Code {
		default:
			s.logger.LogError("get avatars request with query %v failed with unknown err: %v", ids, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	response := map[string]openapi.Image{}
	for _, avatar := range result {
		response[string(avatar.Id)] = openapi.Image{
			Id:     string(avatar.Id),
			Base64: avatar.Base64,
		}
	}
	return openapi.Response(200, openapi.GetAvatarsSucceededResponse{
		Response: response,
	}), nil
}

// GetProfile -
func (s *DefaultAPIService) GetProfile(ctx context.Context, authorization string) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	result, err := s.Profile.GetProfileInfo(profile.UserId(user))
	if err != nil {
		switch err.Code {
		case profile.GetInfoErrorNotFound:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.NO_SUCH_USER,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("get profile request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.GetProfileSucceededResponse{
		Response: profileToOpenapi(result),
	}), nil
}

// SetAvatar -
func (s *DefaultAPIService) SetAvatar(ctx context.Context, authorization string, request openapi.SetAvatarRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	userToMutate := user
	if request.UserId != nil {
		userToMutate = auth.UserId(*request.UserId)
	}
	updated, err := s.Users.UpdateAvatar(request.DataBase64, users.UserId(userToMutate), users.UserId(user))
	if err != nil {
		switch err.Code {
		case users.UpdateAvatarErrorPrivacy:
			return openapi.Response(403, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.PRIVACY_VIOLATION,
					Description: err.Description,
				},
			}), nil
		case users.UpdateAvatarErrorUserNotFound:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.NO_SUCH_USER,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("update email request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.SetAvatarSucceededResponse{
		Response: userToOpenapi(updated),
	}), nil
}

// SetDisplayName -
func (s *DefaultAPIService) SetDisplayName(ctx context.Context, authorization string, request openapi.SetDisplayNameRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	userToMutate := user
	if request.UserId != nil {
		userToMutate = auth.UserId(*request.UserId)
	}
	updated, err := s.Users.UpdateDisplayName(request.DisplayName, users.UserId(userToMutate), users.UserId(user))
	if err != nil {
		switch err.Code {
		case users.UpdateDisplayNameErrorPrivacy:
			return openapi.Response(403, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.PRIVACY_VIOLATION,
					Description: err.Description,
				},
			}), nil
		case users.UpdateDisplayNameErrorNotFound:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.NO_SUCH_USER,
					Description: err.Description,
				},
			}), nil
		case users.UpdateDisplayNameErrorWrongFormat:
			return openapi.Response(422, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.WRONG_FORMAT,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("update display name request %v failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.SetDisplayNameSucceededResponse{
		Response: userToOpenapi(updated),
	}), nil
}

// GetUsers -
func (s *DefaultAPIService) GetUsers(ctx context.Context, authorization string, ids []string) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	users, err := s.Users.Get(common.Map(ids, func(s string) users.UserId {
		return users.UserId(s)
	}), users.UserId(user))
	if err != nil {
		switch err.Code {
		default:
			s.logger.LogError("get users request with query %v failed with unknown err: %v", ids, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.GetUsersSucceededResponse{
		Response: common.Map(users, userToOpenapi),
	}), nil
}

// SearchUsers -
func (s *DefaultAPIService) SearchUsers(ctx context.Context, authorization string, query string) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	users, err := s.Users.Search(query, users.UserId(user))
	if err != nil {
		switch err.Code {
		default:
			s.logger.LogError("search request with query %s failed with unknown err: %v", query, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.SearchUsersSucceededResponse{
		Response: common.Map(users, userToOpenapi),
	}), nil
}

// CreateUser -
func (s *DefaultAPIService) CreateUser(ctx context.Context, authorization string, request openapi.CreateUserRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	created, err := s.Users.CreateUser(users.UserPayload{
		DisplayName:      request.User.DisplayName,
		AvatarBase64Data: request.User.AvatarBase64Data,
	}, users.UserId(user))
	if err != nil {
		switch err.Code {
		case users.CreateUserErrorWrongFormat:
			return openapi.Response(422, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.WRONG_FORMAT,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("create user request %s failed with unknown err: %v", request, err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.CreateUserSucceededResponse{
		Response: userToOpenapi(created),
	}), nil
}

// ConfirmEmail -
func (s *DefaultAPIService) ConfirmEmail(ctx context.Context, authorization string, request openapi.ConfirmEmailRequest) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	if err := s.Verification.ConfirmEmail(verification.UserId(user), request.Code); err != nil {
		switch err.Code {
		case verification.ConfirmEmailErrorWrongConfirmationCode:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INCORRECT_CREDENTIALS,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("send email confirmation code request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.ConfirmEmailSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

// SendEmailConfirmationCode -
func (s *DefaultAPIService) SendEmailConfirmationCode(ctx context.Context, authorization string) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	if err := s.Verification.SendConfirmationCode(verification.UserId(user)); err != nil {
		switch err.Code {
		default:
			s.logger.LogError("send email confirmation code request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.SendEmailConfirmationCodeSucceededResponse{
		Response: map[string]interface{}{},
	}), nil
}

// CreateSpendingsGroup -
func (s *DefaultAPIService) CreateSpendingsGroup(
	context context.Context,
	authorization string,
	request openapi.CreateSpendingsGroupRequest,
) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	group, err := s.Spendings.CreateSpendingsGroup(
		spendingsGroupPayloadFromOpenapi(request.Payload),
		spendings.UserId(user),
	)
	if err != nil {
		switch err.Code {
		case spendings.CreateSpendingsGroupErrorParticipantNotFound:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.NO_SUCH_USER,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("create spending group request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.CreateSpendingsGroupSucceededResponse{
		Response: groupToOpenapi(group),
	}), nil
}

// AddSpending -
func (s *DefaultAPIService) AddSpending(
	context context.Context,
	authorization string,
	request openapi.AddSpendingRequest,
) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	spending, err := s.Spendings.AddSpending(
		spendings.SpendingPayload(spendingPayloadFromOpenapi(request.Payload)),
		spendings.SpendingsGroupId(request.GroupId),
		spendings.UserId(user),
	)
	if err != nil {
		switch err.Code {
		case spendings.AddSpendingErrorNotAllowed:
			return openapi.Response(403, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.PRIVACY_VIOLATION,
					Description: err.Description,
				},
			}), nil
		case spendings.AddSpendingErrorWrongFormat:
			return openapi.Response(422, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.WRONG_FORMAT,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("add spending request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.AddSpendingSucceededResponse{
		Response: spendingToOpenapi(spendingsRepository.Spending(spending)),
	}), nil
}

func (s *DefaultAPIService) GetSpendingGroups(
	context context.Context,
	authorization string,
) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	groups, err := s.Spendings.GetSpendingGroups(spendings.UserId(user))
	if err != nil {
		switch err.Code {
		default:
			s.logger.LogError("get spending groups request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.GetSpendingGroupsSucceededResponse{
		Response: common.Map(groups, groupToOpenapi),
	}), nil
}

func (s *DefaultAPIService) AcceptSpendingGroupInvite(
	context context.Context,
	authorization string,
	request openapi.AcceptSpendingGroupInviteRequest,
) (openapi.ImplResponse, error) {
	user, checkTokenError := s.Auth.CheckToken(extractToken(authorization))
	if checkTokenError != nil {
		return makeResponse(*checkTokenError), nil
	}
	group, err := s.Spendings.AcceptMembershipInGroup(
		spendings.SpendingsGroupId(request.GroupId),
		spendings.UserId(user),
	)
	if err != nil {
		switch err.Code {
		case spendings.AcceptMembershipErrorNotAllowed:
			return openapi.Response(403, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.PRIVACY_VIOLATION,
					Description: err.Description,
				},
			}), nil
		case spendings.AcceptMembershipErrorAlreadyAccepted:
			return openapi.Response(409, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.ALREADY_CONFIRMED,
					Description: err.Description,
				},
			}), nil
		default:
			s.logger.LogError("accept invite request failed with unknown err: %v", err)
			return openapi.Response(500, openapi.ErrorResponse{
				Error: openapi.Error{
					Reason:      openapi.INTERNAL,
					Description: err.Description,
				},
			}), nil
		}
	}
	return openapi.Response(200, openapi.AcceptSpendingGroupInviteSucceededResponse{
		Response: spendingsGroupToOpenapi(group),
	}), nil
}
