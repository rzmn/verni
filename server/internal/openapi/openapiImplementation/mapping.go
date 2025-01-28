package openapiImplementation

import (
	"verni/internal/common"
	"verni/internal/controllers/auth"
	"verni/internal/controllers/profile"
	"verni/internal/controllers/spendings"
	"verni/internal/controllers/users"
	openapi "verni/internal/openapi/go"
	spendingsRepository "verni/internal/repositories/spendings"
)

func sessionToOpenapi(session auth.Session) openapi.Session {
	return openapi.Session{
		Id:           string(session.Id),
		AccessToken:  string(session.AccessToken),
		RefreshToken: string(session.RefreshToken),
	}
}

func userToOpenapi(user users.User) openapi.User {
	return openapi.User{
		Id:          string(user.Id),
		DisplayName: user.DisplayName,
		AvatarId:    (*string)(user.AvatarId),
	}
}

func profileToOpenapi(profile profile.ProfileInfo) openapi.Profile {
	return openapi.Profile{
		User: openapi.User{
			Id:          string(profile.Id),
			DisplayName: profile.DisplayName,
			AvatarId:    (*string)(profile.AvatarId),
		},
		Email:         profile.Email,
		EmailVerified: profile.EmailVerified,
	}
}

func spendingsGroupPayloadFromOpenapi(
	payload openapi.SpendingsGroupPayload,
) spendings.SpendingsGroupPayload {
	return spendings.SpendingsGroupPayload{
		Name:      payload.Name,
		CreatedAt: int64(payload.CreatedAt),
		UserIds: common.Map(payload.UserIds, func(id string) spendingsRepository.UserId {
			return spendingsRepository.UserId(id)
		}),
		Spendings: common.Map(payload.Spendings, spendingPayloadFromOpenapi),
	}
}

func spendingPayloadFromOpenapi(
	payload openapi.SpendingPayload,
) spendingsRepository.SpendingPayload {
	return spendingsRepository.SpendingPayload{
		Name:      payload.Name,
		Currency:  payload.Currency,
		CreatedAt: int64(payload.CreatedAt),
		Amount:    spendingsRepository.SpendingAmount(payload.Amount),
		Shares:    common.Map(payload.Shares, spendingShareFromOpenapi),
	}
}

func spendingShareFromOpenapi(
	share openapi.SpendingShare,
) spendingsRepository.SpendingShare {
	return spendingsRepository.SpendingShare{
		UserId: spendingsRepository.UserId(share.ParticipantId),
		Amount: spendingsRepository.SpendingAmount(share.Amount),
	}
}

func groupToOpenapi(group spendings.SpendingsGroup) openapi.SpendingsGroup {
	return openapi.SpendingsGroup{
		Id:           string(group.Id),
		Name:         group.Name,
		CreatedAt:    int32(group.CreatedAt),
		Participants: common.Map(group.Participants, spendingGroupParticipantToOpenapi),
		Spendings:    common.Map(group.Spendings, spendingToOpenapi),
	}
}

func spendingPayloadToOpenapi(
	payload spendingsRepository.SpendingPayload,
) openapi.SpendingPayload {
	return openapi.SpendingPayload{
		Name:      payload.Name,
		Currency:  payload.Currency,
		CreatedAt: int32(payload.CreatedAt),
		Amount:    int32(payload.Amount),
		Shares:    common.Map(payload.Shares, spendingShareToOpenapi),
	}
}

func spendingsGroupToOpenapi(group spendings.SpendingsGroup) openapi.SpendingsGroup {
	return openapi.SpendingsGroup{
		Id:           string(group.Id),
		Name:         group.Name,
		CreatedAt:    int32(group.CreatedAt),
		Participants: common.Map(group.Participants, spendingGroupParticipantToOpenapi),
		Spendings:    common.Map(group.Spendings, spendingToOpenapi),
	}
}

func spendingGroupParticipantToOpenapi(
	participant spendingsRepository.SpendingsGroupParticipant,
) openapi.SpendingsGroupParticipant {
	return openapi.SpendingsGroupParticipant{
		UserId: string(participant.UserId),
		Status: openapi.SpendingsGroupParticipantStatus(participant.Status),
	}
}

func spendingToOpenapi(
	spending spendingsRepository.Spending,
) openapi.Spending {
	return openapi.Spending{
		Id: string(spending.Id),
		Payload: openapi.SpendingPayload{
			Name:      spending.Payload.Name,
			Currency:  spending.Payload.Currency,
			CreatedAt: int32(spending.Payload.CreatedAt),
			Amount:    int32(spending.Payload.Amount),
			Shares:    common.Map(spending.Payload.Shares, spendingShareToOpenapi),
		},
	}
}

func spendingShareToOpenapi(
	share spendingsRepository.SpendingShare,
) openapi.SpendingShare {
	return openapi.SpendingShare{
		ParticipantId: string(share.UserId),
		Amount:        int32(share.Amount),
	}
}
