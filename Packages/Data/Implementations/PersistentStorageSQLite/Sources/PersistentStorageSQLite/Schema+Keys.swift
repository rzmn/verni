import PersistentStorage
internal import SQLite

extension Schema {
    static var identifierKey: String {
        "id"
    }
    
    static var valueKey: String {
        "value"
    }
}

extension Descriptor {
    func createTable(database: Connection) throws {
        try database.run(Table(id).create { table in
            table.column(Expression<CodableBlob<Key>>(Schema.identifierKey), primaryKey: true)
            table.column(Expression<CodableBlob<Value>>(Schema.valueKey))
        })
    }
}
