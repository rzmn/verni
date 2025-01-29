package operations

import (
	"encoding/json"
	"fmt"
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
	} else {
		return UnknownOperationPayloadType
	}
}

func (o *OpenApiOperation) Data() ([]byte, error) {
	if !openapi.IsZeroValue(o.CreateUser) {
		return json.Marshal(o.CreateUser)
	} else {
		return []byte{}, fmt.Errorf("getting data from %v: %w", o, BadOperation)
	}
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
