package operations

type EntityBindAction struct {
	Watchers []UserId
	Entity   TrackedEntity
}

type PushOperation struct {
	Operation
	EntityBindActions []EntityBindAction
}
