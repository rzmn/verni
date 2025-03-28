package defaultController

import (
	"cmp"
	"encoding/json"
	"fmt"
	"slices"
	"verni/internal/common"
	openapi "verni/internal/openapi/go"
	operationsRepository "verni/internal/repositories/operations"
	pushTokens "verni/internal/repositories/pushNotifications"
	"verni/internal/services/pushNotifications"
)

func (c *defaultController) getDisplayNames(userIds []operationsRepository.UserId) (map[string]string, error) {
	operations, err := c.operationsRepository.Get(
		common.Map(userIds, func(id operationsRepository.UserId) operationsRepository.TrackedEntity {
			return operationsRepository.TrackedEntity{
				Id:   string(id),
				Type: operationsRepository.EntityTypeUser,
			}
		}),
	)
	if err != nil {
		return nil, fmt.Errorf("getting operations: %w", err)
	}
	slices.SortFunc(operations, func(i, j operationsRepository.Operation) int {
		return cmp.Compare(i.CreatedAt, j.CreatedAt)
	})
	displayNames := make(map[string]string)
	for _, operation := range operations {
		data, err := operation.Payload.Data()
		if err != nil {
			return nil, fmt.Errorf("getting data from operation %v: %w", operation, err)
		}
		var converted openapi.SomeOperation
		if err := json.Unmarshal(data, &converted); err != nil {
			return nil, fmt.Errorf("parsing operation from %v payload data: %w", operation, err)
		}
		switch operation.Payload.Type() {
		case operationsRepository.CreateUserOperationPayloadType:
			displayNames[string(converted.CreateUser.UserId)] = converted.CreateUser.DisplayName
		case operationsRepository.UpdateDisplayNameOperationPayloadType:
			displayNames[string(converted.UpdateDisplayName.UserId)] = converted.UpdateDisplayName.DisplayName
		}
	}
	return displayNames, nil
}

func (c *defaultController) getSpendingGroupPayload(
	groupId string,
) (openapi.CreateSpendingGroupOperationCreateSpendingGroup, error) {
	operations, err := c.operationsRepository.Get(
		[]operationsRepository.TrackedEntity{
			{
				Id:   groupId,
				Type: operationsRepository.EntityTypeSpendingGroup,
			},
		},
	)
	if err != nil {
		return openapi.CreateSpendingGroupOperationCreateSpendingGroup{}, fmt.Errorf("getting operations: %w", err)
	}
	for _, operation := range operations {
		data, err := operation.Payload.Data()
		if err != nil {
			return openapi.CreateSpendingGroupOperationCreateSpendingGroup{}, fmt.Errorf("getting data from operation %v: %w", operation, err)
		}
		var converted openapi.SomeOperation
		if err := json.Unmarshal(data, &converted); err != nil {
			return openapi.CreateSpendingGroupOperationCreateSpendingGroup{}, fmt.Errorf("unmarshalling operation: %w", err)
		}
		switch operation.Payload.Type() {
		case operationsRepository.CreateSpendingGroupOperationPayloadType:
			return converted.CreateSpendingGroup, nil
		}
	}
	return openapi.CreateSpendingGroupOperationCreateSpendingGroup{}, fmt.Errorf("no spending group operation found")
}

func (c *defaultController) sendCreateSpendingGroupPush(
	operation openapi.CreateSpendingGroupOperationCreateSpendingGroup,
	usersToNotify []operationsRepository.UserId,
) error {
	displayNames, err := c.getDisplayNames(common.Map(operation.Participants, func(id string) operationsRepository.UserId {
		return operationsRepository.UserId(id)
	}))
	if err != nil {
		return fmt.Errorf("getting display names: %w", err)
	}
	return c.sendPush(
		string(openapi.NEW_SPENDINGS_GROUP),
		nil,
		nil,
		openapi.CreateSpendingGroupPushPayload{
			Csg: openapi.CreateSpendingGroupPushPayloadCsg{
				Gid:  operation.GroupId,
				Gn:   operation.DisplayName,
				Pdns: displayNames,
			},
		},
		usersToNotify,
	)
}

func (c *defaultController) sendCreateSpendingPush(
	operation openapi.CreateSpendingOperationCreateSpending,
	usersToNotify []operationsRepository.UserId,
) error {
	group, err := c.getSpendingGroupPayload(operation.GroupId)
	if err != nil {
		return fmt.Errorf("getting spending group payload: %w", err)
	}
	displayNames, err := c.getDisplayNames(common.Map(group.Participants, func(id string) operationsRepository.UserId {
		return operationsRepository.UserId(id)
	}))
	if err != nil {
		return fmt.Errorf("getting display names: %w", err)
	}
	for _, user := range usersToNotify {
		for _, share := range operation.Shares {
			if share.UserId != string(user) {
				continue
			}
			if err := c.sendPush(
				string(openapi.NEW_SPENDING),
				nil,
				nil,
				openapi.CreateSpendingPushPayload{
					Cs: openapi.CreateSpendingPushPayloadCs{
						Gid:  operation.GroupId,
						Gn:   group.DisplayName,
						Sid:  operation.SpendingId,
						Sn:   operation.Name,
						Pdns: displayNames,
						C:    operation.Currency,
						A:    operation.Amount,
						U:    share.Amount,
					},
				},
				[]operationsRepository.UserId{user},
			); err != nil {
				return fmt.Errorf("error sending push: %w", err)
			}
		}
	}
	return nil
}

func (c *defaultController) sendPush(
	title string,
	subtitle *string,
	body *string,
	payload interface{},
	usersToNotify []operationsRepository.UserId,
) error {
	c.logger.LogInfo("getting push tokens of %v users ids to send push notification %v", len(usersToNotify), payload)
	tokens, err := c.pushTokensRepository.GetPushTokens(common.Map(usersToNotify, func(id operationsRepository.UserId) pushTokens.UserId {
		return pushTokens.UserId(id)
	}))
	if err != nil {
		return fmt.Errorf("getting push tokens: %w", err)
	}
	c.logger.LogInfo("sending push notification %v to tokens %v", payload, tokens)
	for _, tokens := range tokens {
		for _, token := range tokens {
			c.pushNotifications.Alert(pushNotifications.Token(token), title, subtitle, body, payload)
		}
	}
	return nil
}
