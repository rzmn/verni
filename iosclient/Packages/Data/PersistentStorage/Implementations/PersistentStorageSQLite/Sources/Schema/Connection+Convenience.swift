import PersistentStorage
internal import SQLite

extension Connection {
    @StorageActor func getValueForHost<Value: Codable>(
        host: HostId,
        schema: Schema
    ) throws -> Value {
        let value = try prepare(Table(schema.tableName))
            .first { row in
                let id = try row.get(
                    Expression<CodableBlob<String>>(schema.identifierKey)
                ).value
                return id == host
            }?
            .get(Expression<CodableBlob<Value>>(schema.valueKey)).value
        guard let value else {
            throw SQLite.QueryError.unexpectedNullValue(name: "\(schema.tableName)")
        }
        return value
    }
    
    @StorageActor func getOperations<Value: BaseOperationConvertible & Codable>() throws -> [Value] {
        try prepare(Table(Schema.operations.tableName))
            .map { row in
                try row.get(Expression<CodableBlob<Value>>(Schema.operations.valueKey)).value
            }
            .sorted
    }
    
    @StorageActor func upsert<Value: BaseOperationConvertible & Codable>(
        operations: [Value]
    ) throws {
        guard !operations.isEmpty else {
            return
        }
        try run(
            Table(Schema.operations.tableName)
                .insertMany(
                    or: .replace,
                    operations.map { operation in
                        try [
                            Expression(Schema.operations.identifierKey) <- CodableBlob(value: operation.base.operationId),
                            Expression(Schema.operations.valueKey) <- CodableBlob(value: operation),
                        ]
                    }
                )
        )
    }
}
