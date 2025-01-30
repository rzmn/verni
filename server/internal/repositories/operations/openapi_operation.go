package operations

import (
	"encoding/json"
	openapi "verni/internal/openapi/go"
)

type OpenApiOperation struct {
	openapi.Operation
}

func CreateOperation(operation openapi.Operation) Operation {
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
	} else if openapi.IsZeroValue(o.UpdateDisplayName) {
		return UpdateDisplayNameOperationPayloadType
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
	if o.Type() == CreateUserOperationPayloadType {
		return &o.CreateUser.DisplayName
	} else if o.Type() == UpdateDisplayNameOperationPayloadType {
		return &o.UpdateDisplayName.DisplayName
	} else {
		return nil
	}
}

func (o *OpenApiOperation) Data() ([]byte, error) {
	return json.Marshal(o)
}

func (o *OpenApiOperation) TrackedEntities() []TrackedEntity {
	if !openapi.IsZeroValue(o.CreateUser) {
		return []TrackedEntity{
			TrackedEntity{
				Id:   o.CreateUser.UserId,
				Type: EntityTypeUser,
			},
		}
	} else {
		return []TrackedEntity{}
	}
}
