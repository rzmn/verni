import PersistentStorage
import Api
internal import SQLite

extension Connection {
    @StorageActor private func createTable<K: Codable, V: Codable>(schema: Schema, key: K.Type, value: V.Type) throws {
        try run(
            Table(schema.tableName).create { table in
                table.column(
                    Expression<CodableBlob<K>>(schema.identifierKey),
                    primaryKey: true
                )
                table.column(
                    Expression<CodableBlob<V>>(schema.valueKey)
                )
            }
        )
    }
    
    @StorageActor func createTablesForSandbox() throws {
        try createTable(schema: .operations, key: String.self, value: Components.Schemas.Operation.self)
    }
    
    @StorageActor func createTablesForUser() throws {
        try createTable(schema: .operations, key: String.self, value: PersistentStorage.Operation.self)
        try createTable(schema: .refreshToken, key: String.self, value: String.self)
        try createTable(schema: .deviceId, key: String.self, value: String.self)
    }
}
