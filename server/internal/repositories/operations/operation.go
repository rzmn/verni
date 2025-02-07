package operations

type TrackedEntity struct {
	Id   string
	Type EntityType
}

type OperationPayload interface {
	Type() OperationPayloadType
	Data() ([]byte, error)
	TrackedEntities() []TrackedEntity
	IsLarge() bool
	SearchHint() *string
}

type Operation struct {
	OperationId OperationId
	CreatedAt   int64
	AuthorId    UserId
	Payload     OperationPayload
}
