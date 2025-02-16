package defaultRepository_test

import (
	"database/sql"
	"encoding/json"
	"os"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	postgresDb "verni/internal/db/postgres"
	"verni/internal/repositories/operations"
	defaultRepository "verni/internal/repositories/operations/default"
	standartOutputLoggingService "verni/internal/services/logging/standartOutput"
	defaultPathProvider "verni/internal/services/pathProvider/default"
)

var testConfig postgresDb.PostgresConfig

func setupTestDB(t *testing.T) *sql.DB {
	logger := standartOutputLoggingService.New()
	pathProvider := defaultPathProvider.New(logger)
	path := pathProvider.AbsolutePath("./config/test/postgres_storage.json")

	configFile, err := os.ReadFile(path)
	require.NoError(t, err)

	err = json.Unmarshal(configFile, &testConfig)
	require.NoError(t, err)

	db, err := postgresDb.Postgres(testConfig, logger)
	require.NoError(t, err)

	// Clear test data
	_, err = db.Exec("DELETE FROM confirmedOperations")
	require.NoError(t, err)
	_, err = db.Exec("DELETE FROM operationsAffectingEntity")
	require.NoError(t, err)
	_, err = db.Exec("DELETE FROM trackedEntities")
	require.NoError(t, err)
	_, err = db.Exec("DELETE FROM operations")
	require.NoError(t, err)

	return db.(*sql.DB)
}

// Helper function to create a test operation
func createTestOperation(id string) operations.PushOperation {
	return operations.PushOperation{
		Operation: operations.Operation{
			OperationId: operations.OperationId(id),
			CreatedAt:   time.Now().Unix(),
			AuthorId:    operations.UserId("test-author"),
			Payload: &testPayload{
				data:       []byte(`{"test":"data"}`),
				entityType: operations.OperationPayloadType(operations.EntityTypeUser),
				entities: []operations.TrackedEntity{
					{Id: "test-entity", Type: operations.EntityTypeUser},
				},
			},
		},
		EntityBindActions: []operations.EntityBindAction{
			{
				Entity:   operations.TrackedEntity{Id: "test-entity", Type: operations.EntityTypeUser},
				Watchers: []operations.UserId{"test-watcher"},
			},
		},
	}
}

// Test payload implementation
type testPayload struct {
	data       []byte
	entityType operations.OperationPayloadType
	entities   []operations.TrackedEntity
	isLarge    bool
}

func (p *testPayload) Type() operations.OperationPayloadType {
	return p.entityType
}

func (p *testPayload) Data() ([]byte, error) {
	return p.data, nil
}

func (p *testPayload) TrackedEntities() []operations.TrackedEntity {
	return p.entities
}

func (p *testPayload) IsLarge() bool {
	return p.isLarge
}

func (p *testPayload) SearchHint() *string {
	hint := "test-hint"
	return &hint
}

func TestRepository_Push(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("successful push and rollback", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")
		operation := createTestOperation("test-op-1")

		// Act
		work := repo.Push([]operations.PushOperation{operation}, userId, deviceId, true)
		err := work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify operation exists
		ops, err := repo.Get(operation.Payload.TrackedEntities())
		assert.NoError(t, err)
		assert.Len(t, ops, 1)
		assert.Equal(t, operation.OperationId, ops[0].OperationId)

		err = work.Rollback()
		require.NoError(t, err)

		// Assert - operation should not exist after rollback
		ops, err = repo.Get(operation.Payload.TrackedEntities())
		assert.NoError(t, err)
		assert.Empty(t, ops)
	})
}

func TestRepository_PullWithWatcher(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("pull operations with watcher", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")
		operation := createTestOperation("test-op-3")
		operation.EntityBindActions = append(operation.EntityBindActions, operations.EntityBindAction{
			Entity:   operations.TrackedEntity{Id: "test-entity", Type: operations.EntityTypeUser},
			Watchers: []operations.UserId{userId},
		})

		// Push operation first
		work := repo.Push([]operations.PushOperation{operation}, userId, deviceId, false)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		ops, err := repo.Pull(userId, deviceId, operations.OperationTypeRegular)

		// Assert
		assert.NoError(t, err)
		assert.Len(t, ops, 1)
		assert.Equal(t, operation.OperationId, ops[0].OperationId)
	})
}

func TestRepository_PullWithoutWatcher(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("pull operations without watcher", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")
		operation := createTestOperation("test-op-3")

		// Push operation first
		work := repo.Push([]operations.PushOperation{operation}, userId, deviceId, false)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		ops, err := repo.Pull(userId, deviceId, operations.OperationTypeRegular)

		// Assert
		assert.NoError(t, err)
		assert.Empty(t, ops)
	})
}

func TestRepository_Confirm(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("confirm operations", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")
		operation := createTestOperation("test-op-4")
		operation.EntityBindActions = append(operation.EntityBindActions, operations.EntityBindAction{
			Entity:   operations.TrackedEntity{Id: "test-entity", Type: operations.EntityTypeUser},
			Watchers: []operations.UserId{userId},
		})

		// Push operation first
		work := repo.Push([]operations.PushOperation{operation}, userId, deviceId, false)
		err := work.Perform()
		require.NoError(t, err)

		// Verify operation is not pulled before confirmation
		ops, err := repo.Pull(userId, deviceId, operations.OperationTypeRegular)
		assert.NoError(t, err)
		assert.Len(t, ops, 1)

		// Act - Confirm operation
		work = repo.Confirm([]operations.OperationId{operation.OperationId}, userId, deviceId)
		err = work.Perform()

		// Assert
		assert.NoError(t, err)

		// Verify operation is not pulled after confirmation
		ops, err = repo.Pull(userId, deviceId, operations.OperationTypeRegular)
		assert.NoError(t, err)
		assert.Empty(t, ops)
	})
}

func TestRepository_Search(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("search operations", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")
		operation := createTestOperation("test-op-5")

		// Push operation first
		work := repo.Push([]operations.PushOperation{operation}, userId, deviceId, false)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		ops, err := repo.Search(operation.Payload.Type(), "test")

		// Assert
		assert.NoError(t, err)
		assert.Len(t, ops, 1)
		assert.Equal(t, operation.OperationId, ops[0].OperationId)
	})
}

func TestRepository_GetUsers(t *testing.T) {
	db := setupTestDB(t)
	defer db.Close()

	logger := standartOutputLoggingService.New()
	repo := defaultRepository.New(db, logger)

	t.Run("get users tracking entities", func(t *testing.T) {
		// Arrange
		userId := operations.UserId("test-user")
		deviceId := operations.DeviceId("test-device")
		operation := createTestOperation("test-op-6")

		// Push operation first
		work := repo.Push([]operations.PushOperation{operation}, userId, deviceId, false)
		err := work.Perform()
		require.NoError(t, err)

		// Act
		users, err := repo.GetUsers(operation.Payload.TrackedEntities())

		// Assert
		assert.NoError(t, err)
		assert.Contains(t, users, operations.UserId("test-watcher"))
	})
}

func TestMain(m *testing.M) {
	code := m.Run()
	os.Exit(code)
}
