package operations

import (
	"encoding/json"
	openapi "verni/internal/openapi/go"
)

type OpenApiOperation struct {
	openapi.SomeOperation
}

func CreateOperation(operation openapi.SomeOperation) Operation {
	return Operation{
		CreatedAt:   operation.CreatedAt,
		OperationId: OperationId(operation.OperationId),
		AuthorId:    UserId(operation.AuthorId),
		Payload: &OpenApiOperation{
			operation,
		},
	}
}

func (o *OpenApiOperation) Type() string {
	if !openapi.IsZeroValue(o.CreateUser) {
		return CreateUserOperationPayloadType
	} else if !openapi.IsZeroValue(o.UpdateDisplayName) {
		return UpdateDisplayNameOperationPayloadType
	} else if !openapi.IsZeroValue(o.UploadImage) {
		return UploadImageOperationPayloadType
	} else if !openapi.IsZeroValue(o.BindUser) {
		return BindUserOperationPayloadType
	} else if !openapi.IsZeroValue(o.UpdateAvatar) {
		return UpdateAvatarOperationPayloadType
	} else if !openapi.IsZeroValue(o.CreateSpendingGroup) {
		return CreateSpendingGroupOperationPayloadType
	} else if !openapi.IsZeroValue(o.DeleteSpendingGroup) {
		return DeleteSpendingGroupOperationPayloadType
	} else if !openapi.IsZeroValue(o.CreateSpending) {
		return CreateSpendingOperationPayloadType
	} else if !openapi.IsZeroValue(o.DeleteSpending) {
		return DeleteSpendingOperationPayloadType
	} else if !openapi.IsZeroValue(o.UpdateEmail) {
		return UpdateEmailOperationPayloadType
	} else if !openapi.IsZeroValue(o.VerifyEmail) {
		return VerifyEmailOperationPayloadType
	} else {
		return UnknownOperationPayloadType
	}
}

func (o *OpenApiOperation) IsLarge() bool {
	if o.Type() == UploadImageOperationPayloadType {
		return true
	} else {
		return false
	}
}

func (o *OpenApiOperation) SearchHint() *string {
	switch o.Type() {
	case CreateUserOperationPayloadType:
		return &o.CreateUser.DisplayName
	case UpdateDisplayNameOperationPayloadType:
		return &o.UpdateDisplayName.DisplayName
	default:
		return nil
	}
}

func (o *OpenApiOperation) Data() ([]byte, error) {
	return json.Marshal(o)
}

func (o *OpenApiOperation) TrackedEntities() []TrackedEntity {
	switch o.Type() {
	case CreateUserOperationPayloadType:
		return []TrackedEntity{{
			Id:   o.CreateUser.UserId,
			Type: EntityTypeUser,
		}}
	case UpdateDisplayNameOperationPayloadType:
		return []TrackedEntity{{
			Id:   o.UpdateDisplayName.UserId,
			Type: EntityTypeUser,
		}}
	case UpdateAvatarOperationPayloadType:
		return []TrackedEntity{
			{Id: o.UpdateAvatar.UserId, Type: EntityTypeUser},
			{Id: o.UpdateAvatar.ImageId, Type: EntityTypeImage},
		}
	case UploadImageOperationPayloadType:
		return []TrackedEntity{{
			Id:   o.UploadImage.ImageId,
			Type: EntityTypeImage,
		}}
	case BindUserOperationPayloadType:
		return []TrackedEntity{
			{Id: o.BindUser.OldId, Type: EntityTypeUser},
			{Id: o.BindUser.NewId, Type: EntityTypeUser},
		}
	default:
		return []TrackedEntity{}
	}
}
