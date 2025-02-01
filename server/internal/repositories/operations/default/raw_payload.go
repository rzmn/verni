package defaultRepository

import "verni/internal/repositories/operations"

type rawPayload struct {
	payloadType     string
	data            []byte
	trackedEntities []operations.TrackedEntity
	isLarge         bool
	searchHint      *string
}

func (c *rawPayload) Type() string {
	return c.payloadType
}

func (c *rawPayload) Data() ([]byte, error) {
	return c.data, nil
}

func (c *rawPayload) TrackedEntities() []operations.TrackedEntity {
	return c.trackedEntities
}

func (c *rawPayload) IsLarge() bool {
	return c.isLarge
}

func (c *rawPayload) SearchHint() *string {
	return c.searchHint
}
